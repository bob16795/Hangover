import loop
import glfw
import types/font
import events
import audio

template Game*(body: untyped) =
  body

  proc main() =
    var
      data = Setup()
      ctx = initGraphics(data)
      loop = newLoop(60)

    initAudio()
    initUIManager(data.size)

    Initialize()

    setupEventCallbacks(ctx)


    createListener(EVENT_RESIZE, (p: pointer) => loop.forceDraw(ctx))

    deinitFT()

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
