import glfw
import sugar
from loop import GraphicsContext
export glfw.Key

type
  EventId = int
  EventListener = proc(data: pointer)

# template `+`(v: EventId): EventId =
#   cast[EventId](cast[int](v) + 1)

var
  lastEventId: EventId
  listeners: seq[tuple[id: EventId, call: EventListener]]

template createEvent*(name: untyped): untyped =
  var name = lastEventId
  export name
  lastEventId = cast[EventId](cast[int](lastEventId) + 1)

proc sendEvent*(event: EventId, data: pointer) =
  for e in listeners:
    if e.id == event:
      e.call(data)

proc createListener*(event: EventId, call: EventListener) =
  listeners &= (id: event, call: call)

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
    lineInput = true
    lineText = "")
  createListener(EVENT_SET_LINE_TEXT,
    setLineText)
