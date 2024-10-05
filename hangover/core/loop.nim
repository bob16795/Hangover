import sugar
import types/vector2
import types/color
import times
import locks
when not defined(ginGLFM):
  import glfw
else:
  import glfm

import logging
export LOG_INFO

type
  GraphicsContext* = ref object
    ## stores some random graphics data for a loop
    when not defined(ginGLFM):
      window*: Window          ## the game window
    else:
      window*: ptr GLFMDisplay ## the glfm display
    size*: Vector2             ## the screen dimensions
    pos*: Vector2              ## the screen position
    color*: Color              ## color data
    lock*: Lock

  Loop* = object
    ## stores data and runs the main game loop
    targetFPS*: float64
    dt: float64                    ## delta time
    fixedUpdateTime*: float64
    fixedAccumulator: float64
    lastTime*, currentTime*: float32 ## for calculating dt
    done*: bool                    ## true if the loop is over
    updateProc*: (dt: float, delayed: bool) -> bool
    fixedUpdateProc*: (dt: float) -> bool
    drawProc*: (ctx: var GraphicsContext, dt: float32) -> void

var
  globalCtx*: GraphicsContext

proc setFixedUpdateTime*(l: var Loop, t: float64) =
  l.fixedUpdateTime = t

proc lockGraphics(c: var GraphicsContext) =
  c.lock.acquire()
  c.window.makeContextCurrent()

proc unlockGraphics(c: var GraphicsContext) =
  detachCurrentContext()
  c.lock.release()

template withGraphics*(body: untyped) =
  #LOG_INFO "ho->gfx", "lock"
  globalCtx.lockGraphics()
  try:
    body
  finally:
    #LOG_INFO "ho->gfx", "unlock"
    globalCtx.unlockGraphics()

proc newLoop*(fps: float64): Loop =
  ## creates a new loop running at fps
  result.targetFPS = 1.0 / fps
  result.fixedUpdateTime = 1.0 / 50.0
  result.dt = 0

proc forceDraw*(loop: var Loop, ctx: var GraphicsContext) =
  ## forces the loop to draw the window
  let initTime = loop.lastTime

  loop.lastTime = loop.currentTime
  when not defined(ginGLFM):
    loop.currentTime = glfw.getTime()
  when defined(hangui) or defined(ginGLFM):
    loop.currentTime = cpuTime()

  if loop.currentTime - loop.lastTime > loop.targetFPS:
    if loop.lastTime != 0:
      loop.dt = 0

    loop.drawProc(ctx, 1.0)
  else:
    loop.lastTime = initTime

proc update*(loop: var Loop, ctx: var GraphicsContext) =
  ## processes one frame of a loop

  # returns if the loop should stop
  if loop.done:
    return

  # calculate dt
  loop.lastTime = loop.currentTime
  when not defined(ginGLFM):
    loop.currentTime = glfw.getTime()
  when defined(hangui) or defined(ginGLFM):
    loop.currentTime = cpuTime()

  if loop.lastTime != 0:
    loop.dt = loop.currentTime - loop.lastTime

  if loop.fixedUpdateProc != nil:
    loop.fixedAccumulator += loop.dt

    while loop.fixedAccumulator >= loop.fixedUpdateTime:
      if loop.fixedupdateproc(loop.fixedUpdateTime):
        loop.done = true
      loop.fixedAccumulator -= loop.fixedUpdateTime

  # update the game
  if loop.updateProc != nil:
    if loop.updateproc(loop.dt, false):
      loop.done = true

  # render the game
  loop.drawProc(ctx, loop.fixedAccumulator / loop.fixedUpdateTime)

proc update*(loop: var Loop, ctx: var GraphicsContext, time: cdouble) =
  ## processes one frame of a loop

  # calculate dt
  if loop.done:
    return
  loop.lastTime = loop.currentTime
  loop.currentTime = time
  if loop.lastTime != 0:
    loop.dt = loop.currentTime - loop.lastTime

  if loop.fixedUpdateProc != nil:
    loop.fixedAccumulator += loop.dt

    while loop.fixedAccumulator >= loop.fixedUpdateTime:
      if loop.fixedupdateproc(loop.fixedUpdateTime):
        loop.done = true
      loop.fixedAccumulator -= loop.fixedUpdateTime

  # update the game
  if loop.updateProc != nil:
    if loop.updateproc(loop.dt, false):
      loop.done = true

  # render the game
  loop.drawProc(ctx, loop.fixedAccumulator / loop.fixedUpdateTime)
