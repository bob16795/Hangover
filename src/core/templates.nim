import loop
import glfw
import types/font
import events
import audio

template Game*(body: untyped) =

  proc main() =
    proc Setup(): AppData
    proc Initialize()

    var
      pc: float
      loadStatus: string
      data = Setup()
      ctx = initGraphics(data)
      loop = newLoop(60)

    template setPercent(perc: float): untyped =
      pc = perc
      drawLoading(pc, loadStatus)
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        quit()
      finishDraw()
      finishRender(ctx)
      when defined(GinDebug):
        echo "loaded " & $(pc * 100).int & "% - " & loadStatus
    template setStatus(status: string): untyped =
      loadStatus = status
      drawLoading(pc, loadStatus, ctx)
      glfw.pollEvents()
      if glfw.shouldClose(ctx.window):
        quit()
      finishDraw()
      finishRender(ctx)

    body


    initAudio()
    initUIManager(data.size)


    setupEventCallbacks(ctx)

    Initialize()

    deinitFT()
    createListener(EVENT_RESIZE, (p: pointer) => loop.forceDraw(ctx))

    loop.updateProc =
      proc (dt: float): bool =
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          return true
        updateUI(dt)
        return Update(dt)

    loop.drawProc = proc (ctx: GraphicsContext) =
      Draw(ctx)
      drawUI()
      finishRender(ctx)

    while not loop.done:
      loop.update(ctx)

  main()
