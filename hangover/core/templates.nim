when defined(ginGLFM):
  import glfm
else:
  from glfw import pollEvents, shouldClose
  import audio
import hangover/core/types/font
import hangover/core/loop
import hangover/core/events
import hangover/ecs/types
import hangover/ecs/entity
import sugar
import segfaults
import asyncdispatch
import times
import locks

export loop

export asyncdispatch

when defined debug:
  import console

## templates:
## creates a game loop

createEvent(EVENT_UPDATE, true)
createEvent(EVENT_DRAW, true)
createEvent(EVENT_DRAW_UI, true)
createEvent(EVENT_INIT)
createEvent(EVENT_LOADED)
createEvent(EVENT_CLOSE)

var
  mainLoop*: Loop

template Game*(body: untyped) =
  ## the main loop of a game
  ## make sure to set `setup`, `initialize`, `Update`, `Draw` and `gameClose`
  proc setup(): AppData

  var
    pc: float
    loadStatus: string
    ui: bool
    data = setup()
    size = data.size
    ctx: GraphicsContext

  mainLoop = newLoop(60)

  ctx = initGraphics(data)

  proc updateSize(data: pointer): bool {.cdecl.} =
    let res = cast[ptr tuple[w, h: int32]](data)[]
    size = newPoint(res.w.cint, res.h.cint)

  createListener(EVENT_RESIZE, updateSize)

  template noUI() = ui = false
  template drawUIEarly() =
    if ui:
      drawUI()
      ui = false

  when defined debug:
    var lastTime = cpuTime()

  template setStatus(perc: float32, status: string): untyped =
    pc = perc
    loadStatus = status
    when defined debug:
      let newTime = cpuTime()
      LOG_INFO "ho->templates", "Finished `" & loadStatus & "` in " & $int(1000 * (newTime - lastTime)) & "ms"
      lastTime = newTime

  body

  var loadLock: Lock
  var started: bool

  loadLock.initLock()

  proc initThread() {.thread.} =
    {.cast(gcsafe).}:
      withLock loadLock:
        started = true
        initialize()

  proc drawLoadingAsync() {.async.} =
    let time = cpuTime()
    
    var tmp: Thread[void]
    createThread(tmp, initThread)
    
    while not started:
      await sleepAsync(1000.0 / 60.0)

    while true:
      if drawLoading(pc, loadStatus, ctx, size) and tryAcquire(loadLock):
        finishDraw()
        finishRender(ctx)
        LOG_INFO "ho->templates", "Loaded in " & $int((cpuTime() - time) * 1000) & "ms"
        loadLock.release()
        break
      when not defined(ginGLFM):
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          quit()
      finishDraw()
      finishRender(ctx)
      updateAudio(1.0 / 60.0)
      await sleepAsync(1000.0 / 60.0)

  initFT()
  initAudio()
  initUIManager(data.size)

  setupEventCallbacks(ctx)

  waitFor drawLoadingAsync()

  createListener(EVENT_RESIZE, proc(p: pointer): bool {.cdecl.} = mainLoop.forceDraw(ctx))
  #createListener(EVENT_RESIZE_DONE, proc(p: pointer): bool = mainLoop.forceDraw(ctx))
  mainLoop.fixedUpdateProc =
    proc (dt: float): bool =
      return fixedUpdate(dt)

  mainLoop.updateProc =
    proc (dt: float, delayed: bool): bool =
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        return true

      updateUI(dt)
      updateAudio(dt)
      return update(dt, delayed)

  mainLoop.drawProc = proc (ctx: var GraphicsContext, dt: float32) =
    ui = true
    drawGame(ctx, dt)
    if ui:
      drawUI()

    finishrender(ctx)

  try:
    while not mainLoop.done:
      mainLoop.update(ctx)
  except Defect as ex:
    when defined debug:
      raise ex
    else:
      LOG_ERROR "ho->templates", ex.msg
      raise ex
  finally:
    deinitFT()
    gameClose()
  
template GameECS*(name: string, body: untyped) =
  ## creates a ec based game loop
  Game:
    body

    proc initialize(ctx: var GraphicsContext) =
      setupEntities()
      let tmpCtx = ctx
      sendEvent(EVENT_INIT, addr tmpCtx)
      sendEvent(EVENT_LOADED, nil)

    proc update(dt: float32, delayed: bool): bool =
      let tmpDt = dt
      sendEvent(EVENT_UPDATE, addr tmpDt)

    proc drawGame(ctx: var GraphicsContext) =
      let tmpCtx = ctx
      sendEvent(EVENT_DRAW, addr tmpCtx)
      finishDraw()
      sendEvent(EVENT_DRAW_UI, addr tmpCtx)

    proc gameClose() =
      sendEvent(EVENT_CLOSE, nil)
