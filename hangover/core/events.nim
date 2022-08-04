from loop import GraphicsContext
import tables
import oids
import hangover/core/logging
import hangover/core/types/texture
import hangover/core/types/vector2

when not defined(ginGLFM):
  import glfw
  export glfw.Key

when defined debug:
  import macros


type
  EventId* = distinct uint8
    ## an event id
  EventListener* = object
    ## stores a proc that can be attached to an event
    id: Oid
    p: proc(data: pointer): bool

proc `+`(a, b: EventId): EventId {.borrow.}
proc `==`(a, b: EventId): bool {.borrow.}

var
  lastEventId {.compileTime.}: EventId
  listeners: Table[EventId, seq[EventListener]]

when defined debug:
  var
    debugNames {.compileTime.}: Table[EventId, string]
    
  macro getDbgName(x: untyped): string = x.toStrLit()

template createEvent*(name: untyped, hide: bool = false): untyped =
  ## creates an event
  const name = static: lastEventId
  export name

  when defined(debug) and not hide:
    debugNames[name] = getDbgName(name)
  static:
    lastEventId = lastEventId + 1.EventId

proc sendEvent*(event: EventId, data: pointer) =
  ## sends an event to the manager
  when defined debug:
    if event in debugNames:
      LOG_TRACE("ho->events", debugNames[event])
  if event in listeners:
    for call in listeners[event]:
      if call.p(data):
        break

proc createListener*(event: EventId, call: proc (data: pointer): bool): Oid {.discardable.} =
  ## attaches a listener to an event
  
  # create a listener
  let listener = EventListener(p: call, id: genOid())

  # if the event already has a listener add another
  # otherwise make it
  if event in listeners:
    listeners[event] &= listener
  else:
    listeners[event] = @[listener]

proc detachListener*(id: Oid) =
  ## detaches a listener

  # search for the listener
  for tmpEvent in listeners.keys:
    for tmpCall in 0..<len listeners[tmpEvent]:
      if listeners[tmpEvent][tmpCall].id == id:
        listeners[tmpEvent].del(tmpCall)
        return

include events/keyboard
include events/mouse
include events/resize
include events/joystick

proc setupEventCallbacks*(ctx: GraphicsContext) =
  ## sets the default callbacks

  # if using glfm dont glfw stuff
  when not defined(ginGLFM):
    ctx.window.keyCb = keyCb
    ctx.window.framebufferSizeCb = sizeCB
    ctx.window.windowSizeCb = resizeCB
    ctx.window.cursorPositionCb = mouseMoveCb
    ctx.window.mouseButtonCb = mouseButtonCb
    ctx.window.scrollCb = mouseScrollCb
    ctx.window.charCb = charCb

  # setup listeners for keyboard
  createListener(EVENT_START_LINE_ENTER,
                 proc(d: pointer): bool =
                   lineInput = true
                   lineText = "")
  createListener(EVENT_STOP_LINE_ENTER,
                 proc(d: pointer): bool =
                   lineInput = false
                   lineText = "")
  createListener(EVENT_SET_LINE_TEXT,
    setLineText)
