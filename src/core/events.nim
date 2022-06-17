import glfw
import sugar
from loop import GraphicsContext
export glfw.Key
import tables
import oids
import core/types/texture

type
  EventId* = distinct uint8
  EventListener* = object
    id: Oid
    p: proc(data: pointer): bool
    ## a proc that can be attached to an event

proc `+`*(a, b: EventId): EventId {.borrow.}
proc `==`*(a, b: EventId): bool {.borrow.}

var
  lastEventId* {.compileTime.}: EventId
  listeners: Table[EventId, seq[EventListener]]

template createEvent*(name: untyped): untyped =
  ## creates an event
  var name = static: lastEventId
  export name
  static:
    lastEventId = lastEventId + 1.EventId

proc sendEvent*(event: EventId, data: pointer) =
  ## sends an event to the manager
  if event in listeners:
    for call in listeners[event]:
      if call.p(data):
        break

proc createListener*(event: EventId, call: proc (data: pointer): bool): Oid {.discardable.} =
  ## attaches a listener to an event
  let listener = EventListener(p: call, id: genOid())

  if event in listeners:
    listeners[event] &= listener
  else:
    listeners[event] = @[listener]

proc detachListener*(id: Oid) =
  for tmpEvent in listeners.keys:
    for tmpCall in 0..< len listeners[tmpEvent]:
      if listeners[tmpEvent][tmpCall].id == id:
        listeners[tmpEvent].del(tmpCall)
        return

include events/keyboard
include events/mouse
include events/resize
include events/joystick

proc setupEventCallbacks*(ctx: GraphicsContext) =
  ## sets the default callbacks
  ctx.window.keyCb = keyCb
  ctx.window.framebufferSizeCb = sizeCB
  ctx.window.windowSizeCb = resizeCB
  ctx.window.cursorPositionCb = mouseMoveCb
  ctx.window.mouseButtonCb = mouseButtonCb
  ctx.window.charCb = charCb
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
