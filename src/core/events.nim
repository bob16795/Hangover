import glfw
import sugar
from loop import GraphicsContext
export glfw.Key
import tables

type
  EventId* = distinct uint8
  EventListener* = proc(data: pointer)
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
      call(data)

proc createListener*(event: EventId, call: EventListener) =
  ## attaches a listener to an event
  if event in listeners:
    listeners[event] &= call
  else:
    listeners[event] = @[call]


include events/keyboard
include events/mouse
include events/resize

proc setupEventCallbacks*(ctx: GraphicsContext) =
  ## sets the default callbacks
  ctx.window.keyCb = keyCb
  ctx.window.framebufferSizeCb = sizeCB
  ctx.window.windowSizeCb = resizeCB
  ctx.window.cursorPositionCb = mouseMoveCb
  ctx.window.mouseButtonCb = mouseButtonCb
  ctx.window.charCb = charCb
  createListener(EVENT_START_LINE_ENTER,
    proc(d: pointer) =
    lineInput = true
    lineText = "")
  createListener(EVENT_STOP_LINE_ENTER,
    proc(d: pointer) =
    lineInput = false
    lineText = "")
  createListener(EVENT_SET_LINE_TEXT,
    setLineText)
