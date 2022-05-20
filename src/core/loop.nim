import sugar

import types/vector2

import glfw

import os

type
  GraphicsContext* = object
    window*: Window
    size*: Vector2
    pos*: Vector2

  Loop = object
    targetFPS: float64

    lastTime: float64
    timer: float64

    dt*: float64
    currentTime: float64
    nextTime*: float64

    frames: int
    updates: int

    done*: bool

    updateProc*: (dt: float, delayed: bool) -> bool
    drawProc*: (ctx: var GraphicsContext) -> void


proc newLoop*(fps: float64): Loop =
  result.targetFPS = 1.0 / fps
  result.timer = glfw.getTime()
  result.nextTime = result.timer + result.targetFPS
  result.dt = 0
  result.currentTime = 0
  result.frames = 0
  result.updates = 0

proc forceDraw*(loop: var Loop, ctx: var GraphicsContext) =
  loop.drawProc(ctx)
  loop.frames += 1

proc update*(loop: var Loop, ctx: var GraphicsContext) =
  if loop.done:
    return
  loop.lastTime = loop.currentTime
  loop.currentTime = glfw.getTime()
  var delayed: bool
  # if (loop.nextTime > loop.currentTime):
  #   delayed = true
  #   # sleep(((loop.nextTime - loop.currentTime) * 1000).int)
  # else:
  #   delayed = false
  #   loop.nextTime = loop.currentTime
  loop.dt = loop.currentTime - loop.lastTime
  # loop.nextTime += loop.targetFPS

  if loop.updateProc(loop.dt, delayed):
    loop.done = true
  # loop.updates += 1
  loop.dt = 0

  loop.drawProc(ctx)
  # loop.frames += 1
  # if (glfw.getTime() - loop.timer > 1.0):
  #   loop.timer += 1
  #   # echo "FPS: " & $loop.frames
  #   loop.frames = 0
