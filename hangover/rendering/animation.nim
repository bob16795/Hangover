import sprite
import tables
import hangover/core/types/rect
import hangover/core/types/color
import hangover/core/types/texture
import options

#TODO: comment
#TODO: add fsm

type
  AnimationState* = object of Sprite
    frames: seq[Sprite]
    frameTime*: float32

  Animation*[T] = object
    states*: Table[string, AnimationState]
    state*: string
    frame*: int
    counter: float32
    callback: proc(a: T)
    data: T

proc addState*[T](a: var Animation[T], name: string, speed: float32, sprites: seq[Sprite]) =
  a.states[name] = AnimationState(frames: sprites, frameTime: speed)

proc setState*[T](a: var Animation[T], name: string, callback: proc(a: T) = nil, data: T = default(T)) =
  if a.states.hasKey(name):
    a.frame = 0
    a.counter = 0
    a.state = name
    a.callback = callback
    a.data = data

proc getStateFrame*[T](a: Animation[T]): Sprite =
  let state = a.states[a.state].frames
  return state[a.frame mod len(state)]

proc update*[T](a: var Animation[T], dt: float32) =
  let stateTime = a.states[a.state].frameTime
  a.counter += dt
  while a.counter > stateTime:
    a.frame += 1
    a.counter -= stateTime
  if a.frame >= len(a.states[a.state].frames):
    a.frame = 0
    if not a.callback.isNil:
      a.callback(a.data)

proc draw*[T](
  a: Animation[T],
  r: Rect,
  rotation: float32 = 0,
  color: Color = newColor(255, 255, 255),
  contrast: ContrastEntry = ContrastEntry(mode: fg),
) =
  getStateFrame(a).draw(r.location, rotation, r.size, color, contrast = contrast)
