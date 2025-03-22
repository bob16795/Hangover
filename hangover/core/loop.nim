import sugar
import types/vector2
import types/color
import times
import locks
import glfw

import logging
export LOG_INFO

type
  GraphicsContext* = ref object
    ## stores some random graphics data for a loop
    window*: Window      ## the game window
    size*: Vector2             ## the screen dimensions
    pos*: Vector2              ## the screen position
    color*: Color              ## color data
    lock*: Lock

  Loop* = object
    ## stores data and runs the main game loop
    targetFPS*: float32
    dt: float32                    ## delta time
    fixedUpdateTime*: float32
    fixedAccumulator: float32
    lastTime*, currentTime*: float32 ## for calculating dt
    done*: bool                    ## true if the loop is over
    updateProc*: proc (dt: float, delayed: bool)
    fixedUpdateProc*: proc (dt: float)
    drawProc*: proc (ctx: var GraphicsContext, dt: float32)
          
var
  globalCtx*: GraphicsContext


proc lockGraphics(ctx: var GraphicsContext) =
  ctx.lock.acquire()
  ctx.window.makeContextCurrent()

proc unlockGraphics(ctx: var GraphicsContext) =
  detachCurrentContext()
  ctx.lock.release()

template withGraphics*(body: untyped) =
  globalCtx.lockGraphics()
  try: body
  finally: globalCtx.unlockGraphics()

proc setFixedUpdateTime*(l: var Loop, t: float64) =
  l.fixedUpdateTime = t

proc updateFPS*(l: var Loop) =
  withGraphics:
    l.targetFPS = 1.0 / glfw.getPrimaryMonitor().videoMode.refreshRate.float64

proc newLoop*(fps: float64): Loop =
  ## creates a new loop running at fps
  result.targetFPS = 1.0 / fps
  result.fixedUpdateTime = 1.0 / 50.0
  result.dt = 0

proc forceDraw*(loop: var Loop, ctx: var GraphicsContext) =
  ## forces the loop to draw the window
  let initTime = loop.lastTime

  loop.lastTime = loop.currentTime
  loop.currentTime = glfw.getTime()

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
  loop.currentTime = glfw.getTime()

  if loop.lastTime != 0:
    loop.dt = loop.currentTime - loop.lastTime

  if loop.fixedUpdateProc != nil:
    loop.fixedAccumulator += loop.dt

    while loop.fixedAccumulator >= loop.fixedUpdateTime:
      loop.fixedupdateproc(loop.fixedUpdateTime)

      loop.fixedAccumulator -= loop.fixedUpdateTime

  # update the game
  if loop.updateProc != nil:
    loop.updateproc(loop.dt, false)

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
      loop.fixedupdateproc(loop.fixedUpdateTime)
      loop.fixedAccumulator -= loop.fixedUpdateTime

  # update the game
  if loop.updateProc != nil:
    loop.updateproc(loop.dt, false)

  # render the game
  loop.drawProc(ctx, loop.fixedAccumulator / loop.fixedUpdateTime)
