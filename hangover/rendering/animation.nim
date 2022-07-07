import sprite
import tables
import hangover/core/types/rect

#TODO: comment
#TODO: add fsm

type
  AnimationState* = object
    frames: seq[Sprite]
    frameTime*: float32

  Animation* = object
    states*: Table[string, AnimationState]
    state*: string
    frame: int
    counter: float32
    callback: proc()

proc addState*(a: var Animation, name: string, speed: float32, sprites: seq[Sprite]) =
  a.states[name] = AnimationState(frames: sprites, frameTime: speed)

proc setState*(a: var Animation, name: string, callback: proc() = nil) =
  if a.states.hasKey(name):
    a.frame = 0
    a.counter = 0
    a.state = name
    a.callback = callback

proc getStateFrame*(a: Animation): Sprite =
  let state = a.states[a.state].frames
  return state[a.frame mod len(state)]

proc update*(a: var Animation, dt: float32) =
  let stateTime = a.states[a.state].frameTime
  a.counter += dt
  while a.counter > stateTime:
    a.frame += 1
    a.counter -= stateTime
  if a.frame >= len(a.states[a.state].frames):
    if not a.callback.isNil:
      a.callback()
    a.frame = 0

proc draw*(a: Animation, r: Rect, rotation: float32 = 0) =
  getStateFrame(a).draw(r.location, rotation, r.size)
