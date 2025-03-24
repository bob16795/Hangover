import tables
import oids
import hangover/core/logging
import hangover/core/loop
import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/point
import options
import sequtils
import locks

when not defined(ginGLFM):
  import glfw
  export glfw.Key

when defined debug:
  import macros

type
  Event*[T] = object
    ## an event object
    lock: Lock
    count: int
    listeners: ptr UncheckedArray[EventListener[T]]
    onCrash: bool

    when defined debug:
      name: Option[string]

  EventListener*[T] = object
    ## stores a proc that can be attached to an event
    id: Oid
    when T is void:
      p: proc(): bool {.gcsafe.}
    else:
      p: proc(data: T): bool {.gcsafe.}

when defined debug:
  macro getDbgName(x: untyped): string = x.toStrLit()

var eventsCrashed*: bool

type
  EventFlag* = enum
    hideLogs,
    sendOnCrash

template createEvent*[T](
  eventName: untyped,
  flags: set[EventFlag] = {}, 
): untyped =
  ## creates an event
  var eventName = Event[T]()
  
  export eventName

  when sendOnCrash in flags:
    eventName.onCrash = true
    eventName.lock.initLock()

  when defined(debug) and hideLogs notin flags:
    eventName.name = some(getDbgName(eventName))

{.push checks: off.}
proc send*[T](event: var Event[T], data: T) {.inline.} =
  ## sends an event  
  if eventsCrashed and not event.onCrash: return

  ## sends an event to the manager
  when defined debug:
    if event.name.isSome():
      LOG_TRACE("ho->events", event.name.get())

  for call in event.listeners.toOpenArray(0, event.count):
    if call.p(data):
      break

proc send*(event: var Event[void]) {.inline.} =
  ## sends an event  
  
  if eventsCrashed and not event.onCrash: return

  when defined debug:
    if event.name.isSome():
      LOG_TRACE("ho->events", event.name.get())
  
  for call in event.listeners.toOpenArray(0, event.count):
    if call.p():
      break
{.pop.}

proc listen*[T](event: var Event[T], call: proc (data: T): bool {.gcsafe.}): Oid {.gcsafe, discardable.} =
  ## attaches a listener to an event
  
  # create a listener
  let listener = EventListener[T](p: call, id: genOid())

  # if the event already has a listener add another
  # otherwise make it
  withLock event.lock:
    event.count += 1
    event.listeners = cast[ptr UncheckedArray[EventListener[T]]](
      reallocShared(event.listeners, event.count * sizeof(EventListener[T]))
    )
    event.listeners[event.count - 1] = listener

proc listen*(event: var Event[void], call: proc (): bool {.gcsafe.}): Oid {.gcsafe, discardable.} =
  ## attaches a listener to an event
  
  # create a listener
  let listener = EventListener[void](p: call, id: genOid())

  # if the event already has a listener add another
  # otherwise make it
  withLock event.lock:
    event.count += 1
    event.listeners = cast[ptr UncheckedArray[EventListener[void]]](
      reallocShared(event.listeners, event.count * sizeof(EventListener[void]))
    )
    event.listeners[event.count - 1] = listener

proc remove*[T](event: var Event[T], id: Oid) =
  ## detaches a listener

  # search for the listener
  withLock event.lock:
    var ins = 0
    for tmpCall in 0..<event.count:
      event.listeners[ins] = event.listeners[tmpCall]
      if event.listeners[tmpCall].id != id:
        ins += 1
    event.count = ins
    event.listeners = cast[ptr UncheckedArray[EventListener[T]]](
      reallocShared(event.listeners, event.count * sizeof(EventListener[T])) 
    )

include events/keyboard
include events/mouse
include events/resize
include events/dragdrop

proc setupEventCallbacks*(ctx: GraphicsContext) =
  ## sets the default callbacks

  # if using glfm dont glfw stuff
  ctx.window.keyCb = keyCb
  ctx.window.framebufferSizeCb = sizeCB
  ctx.window.windowSizeCb = resizeCB
  ctx.window.windowFocusCb = focusCb
  ctx.window.cursorPositionCb = mouseMoveCb
  ctx.window.mouseButtonCb = mouseButtonCb
  ctx.window.scrollCb = mouseScrollCb
  ctx.window.charCb = charCb
  ctx.window.dropCb = dropCb

  # setup listeners for keyboard
  eventStartLineEnter.listen do () -> bool {.gcsafe.}:
    lineInput = true
    setLineText("")

  eventStopLineEnter.listen do () -> bool {.gcsafe.}:
    lineInput = false
    lineInputNew = false
    setLineText("")

  eventSetLineEnter.listen do (data: string) -> bool:
    setLineText(data)
