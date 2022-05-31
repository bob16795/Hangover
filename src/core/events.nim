import glfw
import sugar
from loop import GraphicsContext
export glfw.Key
import tables

type
  EventId = int
  EventListener = proc(data: pointer)

# template `+`(v: EventId): EventId =
#   cast[EventId](cast[int](v) + 1)

var
  lastEventId: EventId
  listeners: Table[EventId, seq[EventListener]]

template createEvent*(name: untyped): untyped =
  var name = lastEventId
  export name
  lastEventId = cast[EventId](cast[int](lastEventId) + 1)

proc sendEvent*(event: EventId, data: pointer) =
  if event in listeners:
    for call in listeners[event]:
      call(data)

proc createListener*(event: EventId, call: EventListener) =
  if event in listeners:
    listeners[event] &= call
  else:
    listeners[event] = @[call]


include events/keyboard
include events/mouse
include events/resize

proc setupEventCallbacks*(ctx: GraphicsContext) =
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
