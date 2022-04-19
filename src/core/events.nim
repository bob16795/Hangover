import types/graphicsContext
import glfw
import sugar

type
  EventId = int
  EventListener = proc(data: pointer)

template `+`(v: EventId): EventId =
  cast[EventId](cast[int](v) + 1)

var
  lastEventId: EventId
  listeners: seq[tuple[id: EventId, call: EventListener]]

template createEvent(name: untyped): untyped =
  var name = lastEventId
  export name
  lastEventId = + lastEventId

proc sendEvent(event: EventId, data: pointer) =
  for e in listeners:
    if e.id == event:
      e.call(data)

proc createListener*(event: EventId, call: EventListener) =
  listeners &= (id: event, call: call)

include events/input
include events/resize

proc setupEventCallbacks*(ctx: GraphicsContext) =
  ctx.window.keyCb = keyCb
  ctx.window.framebufferSizeCb = resizeCB
