import loop
import glfw
import types/font
import events

template Game*(body: untyped) =
  body

  proc main() =
    var
      data = Setup()
      ctx = initGraphics(data)
      loop = newLoop(60)

    Initialize()

    setupEventCallbacks(ctx)

    deinitFT()

    loop.updateProc =
      proc (dt: float): bool =
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          return true
        return Update(dt)

    loop.drawProc =
      proc (dt: float, ctx: GraphicsContext) =
        Draw(dt, ctx)
        finishRender(ctx)

    while not loop.done:
      loop.update(ctx)

  main()
