import sugar

import types/vector2
import types/color
import times

when not defined(ginGLFM):
  import glfw
else:
  import glfm

import os

type
  GraphicsContext* = object
    ## stores some random graphics data for a loop
    when not defined(ginGLFM):
      window*: Window
    else:
      window*: ptr GLFMDisplay
    size*: Vector2
    pos*: Vector2
    color*: Color

  Loop* = object
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
  loop.lastTime = loop.currentTime
  when not defined(ginGLFM):
    loop.currentTime = glfw.getTime()
  when defined(hangui) or defined(ginGLFM):
    loop.currentTime = cpuTime()
  var delayed: bool
  if loop.lastTime != 0:
    loop.dt = loop.currentTime - loop.lastTime

  if loop.updateproc(loop.dt, delayed):
    loop.done = true

  loop.drawProc(ctx)

proc update*(loop: var Loop, ctx: var GraphicsContext) =
  ## processes one frame of a loop
  if loop.done:
    echo "loop done"
    return
  loop.lastTime = loop.currentTime
  when not defined(ginGLFM):
    loop.currentTime = glfw.getTime()
  when defined(hangui) or defined(ginGLFM):
    loop.currentTime = cpuTime()
  var delayed: bool
  if loop.lastTime != 0:
    loop.dt = loop.currentTime - loop.lastTime

  if loop.updateproc(loop.dt, delayed):
    loop.done = true
  loop.dt = 0

  loop.drawProc(ctx)
