import tables
import oids
import hangover/core/logging
from hangover/core/loop import GraphicsContext
import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/point
import options

when not defined(ginGLFM):
  import glfw
  export glfw.Key

when defined debug:
  import macros

type
  Event*[T] = object
    ## an event object
    listeners: seq[EventListener[T]]
    onCrash: bool

    when defined debug:
      name: Option[string]
  

  EventListener*[T] = object
    ## stores a proc that can be attached to an event
    id: Oid
    when T is void:
      p: proc(): bool
    else:
      p: proc(data: T): bool

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

  when defined(debug) and hideLogs notin flags:
    eventName.name = some(getDbgName(eventName))

proc send*[T](event: Event[T], data: T) =
  ## sends an event  
  if eventsCrashed and not event.onCrash: return

  ## sends an event to the manager
  when defined debug:
    if event.name.isSome():
      LOG_TRACE("ho->events", event.name.get())
  
  for call in event.listeners:
    if call.p(data):
      break

proc listen*[T](event: var Event[T], call: proc (data: T): bool): Oid {.discardable.} =
  ## attaches a listener to an event
  
  # create a listener
  let listener = EventListener[T](p: call, id: genOid())

  # if the event already has a listener add another
  # otherwise make it
  event.listeners &= listener

proc remove*[T](event: var Event[T], id: Oid) =
  ## detaches a listener

  # search for the listener
  for tmpCall in 0..<len event.listeners:
    if event.listeners[tmpCall].id == id:
      event.listeners.del(tmpCall)
      return

proc send*(event: Event[void]) =
  ## sends an event  
  
  if eventsCrashed and not event.onCrash: return

  when defined debug:
    if event.name.isSome():
      LOG_TRACE("ho->events", event.name.get())
  
  for call in event.listeners:
    if call.p():
      break

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
  eventStartLineEnter.listen do () -> bool:
    lineInput = true
    setLineText("")

  eventStopLineEnter.listen do () -> bool:
    lineInput = false
    lineInputNew = false
    setLineText("")

  eventSetLineEnter.listen do (data: string) -> bool:
    setLineText(data)
