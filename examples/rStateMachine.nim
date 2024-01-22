import hangover
import random
import sugar
import os

type
  States = enum
    fsA
    fsB
    fsQuit

  GameStateData = ref object of RootObj

  GameState[S] = ref object of RStateMachineState[S]
    data: GameStateData

method draw(state: GameStateData) {.base.} =
  echo "lol"

method draw(state: GameState) {.base.} =
  if state.data == nil:
    discard
  else:
    state.data.draw()

method init(state: var GameState) =
  echo "init"

method deinit(state: var GameState) =
  echo "deinit"

Game:
  var
    bg: Color
    fsm: RStateMachine[States]

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext, size: Point) =
    clearBuffer(ctx, bg)

  proc Setup(): AppData =
    bg = newColor(0, 0, 255)
    result = newAppData()
    result.name = "Minimal Hangover Template"

  proc Initialize(ctx: ptr GraphicsContext) {.async.} =
    fsm = newRStateMachine[States](
      [
        RStateMachineState[States](GameState[States](
          conds: @[
            newRFlag(0, fsB),
          ]
        )),
        RStateMachineState[States](GameState[States](
          conds: @[
            newRFlag(0, fsB),
          ]
        )),
        RStateMachineState[States](GameState[States](
          conds: @[
          ]
        )),
      ]
    )

  proc Update(dt: float, delayed: bool): bool =
    discard

  proc Draw(ctx: var GraphicsContext) =
    clearBuffer(ctx, bg)
    GameState[States](fsm.getStateData()).draw()

  proc gameClose() =
    discard
