import loop
import glfw
import types/font
import events
import audio
import ecs/types
import sugar

createEvent(EVENT_UPDATE)
createEvent(EVENT_DRAW)
createEvent(EVENT_DRAW_UI)
createEvent(EVENT_INIT)
createEvent(EVENT_CLOSE)

template Game*(body: untyped) =
  ## the main loop of a game
  ## make sure to set `Setup`, `Initialize`, `Update`, `Draw` and `gameClose`

  proc main() =
    proc Setup(): AppData

    var
      pc: float
      loadStatus: string
      ui: bool
      data = Setup()
      ctx = initGraphics(data)
      loop = newLoop(60)
      size = data.size

    proc UpdateSize(data: pointer): bool =
      var res = cast[ptr tuple[w, h: int32]](data)[]
      size = newPoint(res.w.cint, res.h.cint)

    createListener(EVENT_RESIZE, UpdateSize)

    template setPercent(perc: float): untyped =
      pc = perc
      drawLoading(pc, loadStatus, ctx, size)
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        quit()
      finishDraw()
      finishRender(ctx)
      when defined(GinDebug):
        echo "loaded " & $(pc * 100).int & "% - " & loadStatus
    template setStatus(status: string): untyped =
      loadStatus = status
      drawLoading(pc, loadStatus, ctx, size)
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        quit()
      finishDraw()
      finishRender(ctx)
    template noUI() = ui = false
    template drawUIEarly() =
      drawUI()
      ui = false

    body

    initAudio()
    initUIManager(data.size)

    setupEventCallbacks(ctx)

    Initialize(ctx)
    
    var tmpSize: tuple[w, h: int32]
    tmpSize.w = size.x.int32
    tmpSize.h = size.y.int32
    sendEvent(EVENT_RESIZE, addr tmpSize)

    deinitFT()

    createListener(EVENT_RESIZE, proc(p: pointer): bool = loop.forceDraw(ctx))
    createListener(EVENT_RESIZE_DONE, proc(p: pointer): bool = loop.forceDraw(ctx))
    

    loop.updateProc =
      proc (dt: float, delayed: bool): bool =
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          return true
        updateUI(dt)
        updateAudio()
        return Update(dt, delayed)

    loop.drawProc = proc (ctx: var GraphicsContext) =
      ui = true
      Draw(ctx)
      if ui:
        drawUI()
      finishRender(ctx)

    while not loop.done:
      loop.update(ctx)

    gameClose()

  main()

template GameECS*(name: string, body: untyped) =
  Game:
    body

    proc Initialize(ctx: GraphicsContext) = 
      var tmpCtx = ctx
      sendEvent(EVENT_INIT, addr tmpCtx)

    proc Update(dt: float32, delayed: bool): bool =
      var tmpDt = dt
      sendEvent(EVENT_UPDATE, addr tmpDt)

    proc Draw(ctx: GraphicsContext) =
      var tmpCtx = ctx
      sendEvent(EVENT_DRAW, addr tmpCtx)
      sendEvent(EVENT_DRAW_UI, addr tmpCtx)
    
    proc gameClose() =
      sendEvent(EVENT_CLOSE, nil)
