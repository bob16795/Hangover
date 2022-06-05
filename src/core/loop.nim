import sugar

import types/vector2

import glfw

import os

type
  GraphicsContext* = object
    ## stores some random graphics data for a loop
    window*: Window
    size*: Vector2
    pos*: Vector2

  Loop = object
    targetFPS: float64

    dt*: float64

    lastTime, currentTime: float32

    frames: int
    updates: int

    done*: bool

    updateProc*: (dt: float, delayed: bool) -> bool
    drawProc*: (ctx: var GraphicsContext) -> void


proc newLoop*(fps: float64): Loop =
  ## creates a new loop running at fps
  result.targetFPS = 1.0 / fps
  result.dt = 0
  result.frames = 0
  result.updates = 0

proc forceDraw*(loop: var Loop, ctx: var GraphicsContext) =
  ## forces the loop to draw the window
  loop.drawProc(ctx)
  loop.frames += 1

proc update*(loop: var Loop, ctx: var GraphicsContext) =
  ## processes one frame of a loop
  if loop.done:
    return
  loop.lastTime = loop.currentTime
  loop.currentTime = glfw.getTime()
  var delayed: bool
  if loop.lastTime != 0:
    loop.dt = loop.currentTime - loop.lastTime

  if loop.updateProc(loop.dt, delayed):
    loop.done = true
  loop.dt = 0

  loop.drawProc(ctx)
