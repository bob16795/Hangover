import sugar

import glfw

import os

type
  GraphicsContext* = object
    window*: Window
  Loop = object
    targetFPS: float64

    lastTime: float64
    timer: float64

    dt*: float64
    currentTime: float64
    nextTime: float64

    frames: int
    updates: int

    done*: bool

    updateProc*: (dt: float) -> bool
    drawProc*: (ctx: GraphicsContext) -> void


proc newLoop*(fps: float64): Loop =
  result.targetFPS = 1.0 / fps
  result.timer = glfw.getTime()
  result.nextTime = result.timer + result.targetFPS
  result.dt = 0
  result.currentTime = 0
  result.frames = 0
  result.updates = 0

proc forceDraw*(loop: var Loop, ctx: GraphicsContext) =
  loop.drawProc(ctx)
  loop.frames += 1

proc update*(loop: var Loop, ctx: GraphicsContext) =
  if loop.done:
    return
  loop.lastTime = loop.currentTime
  loop.currentTime = glfw.getTime()
  if (loop.nextTime > loop.currentTime):
    sleep(((loop.nextTime - loop.currentTime) * 1000).int)
  else:
    loop.nextTime = loop.currentTime
  loop.dt = loop.currentTime - loop.lastTime
  loop.nextTime += loop.targetFPS

  if loop.updateProc(loop.dt):
    loop.done = true
  loop.updates += 1
  loop.dt = 0

  loop.drawProc(ctx)
  loop.frames += 1
  if (glfw.getTime() - loop.timer > 1.0):
    loop.timer += 1
    # echo "FPS: " & $loop.frames
    loop.frames = 0
