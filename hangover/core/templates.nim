when defined(ginGLFM):
  import glfm
else:
  import glfw
  import audio
import hangover/core/types/font
import hangover/core/loop
import hangover/core/events
import hangover/ecs/types
import hangover/ecs/entity
import sugar

## templates:
## creates a game loop 

createEvent(EVENT_UPDATE)
createEvent(EVENT_DRAW)
createEvent(EVENT_DRAW_UI)
createEvent(EVENT_INIT)
createEvent(EVENT_LOADED)
createEvent(EVENT_CLOSE)

proc NimMain() {.importc.}

template Game*(body: untyped) =
  ## the main loop of a game
  ## make sure to set `Setup`, `Initialize`, `Update`, `Draw` and `gameClose`
  
  when not defined(ginGLFM):
    when defined(hangui):
      body

      proc libEvent*(id: EventId, data: pointer) {.exportc, cdecl, dynlib.} =
        if id == EVENT_MOUSE_MOVE:
          var dat = cast[ptr tuple[x, y: float64]](data)[]
          dat.x += textureOffset.x
          dat.y += textureOffset.y
          sendEvent(id, addr dat)
          return
        sendEvent(id, data)
      
      proc libGetEntities*(): seq[EntityEntry] {.exportc, cdecl, dynlib.} =
        return entityList
      
      proc libInit*(): GraphicsContext {.exportc, cdecl, dynlib.} =
        result = GraphicsContext()
        NimMain()
        loadExtensions()
        var data = Setup()
        result.color = data.color
        setupTexture()
        initFT()
        initAudio()
        initUIManager(newPoint(400, 300))
        Initialize(result)
        createListener(EVENT_RESIZE, resizeBuffer)

      
      proc libUpdate*(dt: float32): bool {.exportc, cdecl, dynlib.} =
        updateUI(dt)
        updateAudio()
        return Update(dt, false)

      proc libDraw*(ctx: GraphicsContext) {.exportc, cdecl, dynlib.} =
        var color = ctx.color
        glClearColor(color.rf, color.gf, color.bf, color.af)
        glClear(GL_COLOR_BUFFER_BIT)
        Draw(ctx)
        finishDraw()
        #glFlush()

    else:
      proc ginMain() =
        proc Setup(): AppData

        var
          pc: float
          loadStatus: string
          ui: bool
          data = Setup()
          loop = newLoop(60)
          size = data.size
          ctx: GraphicsContext
        
        ctx = initGraphics(data)

        proc UpdateSize(data: pointer): bool =
          var res = cast[ptr tuple[w, h: int32]](data)[]
          size = newPoint(res.w.cint, res.h.cint)

        createListener(EVENT_RESIZE, UpdateSize)

        template setPercent(perc: float): untyped =
          pc = perc
          drawLoading(pc, loadStatus, ctx, size)
          when not defined(ginGLFM):
            glfw.pollEvents()
            if glfw.shouldClose(ctx.window):
              quit()
          finishDraw()
          finishRender(ctx)
        template setStatus(status: string): untyped =
          loadStatus = status
          drawLoading(pc, loadStatus, ctx, size)
          when not defined(ginGLFM):
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
        #createListener(EVENT_RESIZE_DONE, proc(p: pointer): bool = loop.forceDraw(ctx))
        

        loop.updateProc =
          proc (dt: float, delayed: bool): bool =
            when not defined(ginGLFM):
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
          finishrender(ctx)

        while not loop.done:
          loop.update(ctx)
        gameClose()
        
      ginMain()
  else:
    var nimInit* = true
    type
      GinApp* = object
        started*: bool
        init*: bool
        ui*: bool
        data*: AppData
        loop*: Loop
        size*: Point
        ctx*: GraphicsContext

    var app: GinApp
    
    template setStatus(status: string): untyped = discard
    template setPercent(status: untyped): untyped = discard
    template noUI() = app.ui = false

    proc onFrame*(display: ptr GLFMDisplay; frameTime: cdouble) =
      if not app.init:
        proc Setup(): AppData

        app.data = Setup()
        app.ctx = initGraphics(app.data)

        initUIManager(app.size)

        app.loop = newLoop(60)
        app.ctx.window = display
        template drawUIEarly() =
          drawUI()
          app.ui = false
        
        body

        Initialize(app.ctx)

        app.loop.updateProc =
          proc (dt: float, delayed: bool): bool =
            updateAudio()
            updateUI(dt)
            return Update(dt, delayed)

        app.loop.drawProc = proc (ctx: var GraphicsContext) =
          app.ui = true
          Draw(ctx)
          if app.ui:
            drawUI()
          finishrender(ctx)
        app.init = true
        var tmpSize = (app.size.x.int32, app.size.y.int32)
        sendEvent(EVENT_RESIZE, addr tmpSize)

        createListener(EVENT_CLOSE, proc(d: pointer): bool = gameClose())

      clearBuffer(app.ctx, app.ctx.color)
      app.loop.update(app.ctx, frameTime)

    proc onResize*(display: ptr GLFMDisplay, w, h: cint) =
        var tmpResize = (w.int32, h.int32)
        app.size = newPoint(w.int, h.int)
        sendEvent(EVENT_RESIZE, addr tmpResize)
    
    proc onCreate*(display: ptr GLFMDisplay, w, h: cint) =
        var tmpSize: tuple[w, h: int32]
        tmpSize = (w.int32, h.int32)
        app.size = newPoint(w.int, h.int)
        sendEvent(EVENT_RESIZE, addr tmpSize)
        
    proc onTouch*(display: ptr GLFMDisplay; touch: cint; phase: GLFMTouchPhase; x: cdouble;
             y: cdouble): bool =
      var data = (x.float64 + textureOffset.x.float64, y.float64 + textureOffset.y.float64, touch)
      sendEvent(EVENT_MOUSE_MOVE, addr data)
      if phase == GLFMTouchPhaseBegan:
        sendEvent(EVENT_MOUSE_CLICK, addr touch)
      elif phase == GLFMTouchPhaseEnded:
        sendEvent(EVENT_MOUSE_RELEASE, addr touch)
    
    proc onKey*(display: ptr GLFMDisplay; keyCode: Key; action: KeyAction;
           modifiers: cint): bool =
      case action:
        of keyActionPressed:
          sendEvent(EVENT_PRESS_KEY, addr keyCode)
        of keyActionReleased:
          sendEvent(EVENT_RELEASE_KEY, addr keyCode)
        else:
          discard

    proc onDestroy*(display: ptr GLFMDisplay) =
      sendEvent(EVENT_CLOSE, nil)

    proc glfmMain*(display: ptr GLFMDisplay) {.exportc, cdecl.} =
      NimMain()
      app = GinApp()
      glfmSetDisplayConfig(display, GLFMRenderingAPIOpenGLES32,
                           GLFMColorFormatRGBA8888, GLFMDepthFormatNone,
                           GLFMStencilFormatNone, GLFMMultisampleNone)
      glfmSetDisplayChrome(display, GLFMUserInterfaceChromeFullscreen)
      glfmSetUserData(display, addr app)

      glfmSetSurfaceCreatedFunc(display, onCreate)
      glfmSetSurfaceDestroyedFunc(display, onDestroy)
      glfmSetMainLoopFunc(display, onFrame)
      glfmSetSurfaceResizedFunc(display, onResize)

      glfmSetTouchFunc(display, onTouch)
      glfmSetKeyFunc(display, onKey)
      glfmSetMultitouchEnabled(display, true)

    
template GameECS*(name: string, body: untyped) =
  ## creates a ec based game loop
  Game:
    body

    proc Initialize(ctx: GraphicsContext) = 
      setupEntities()
      var tmpCtx = ctx
      sendEvent(EVENT_INIT, addr tmpCtx)
      sendEvent(EVENT_LOADED, nil)

    proc Update(dt: float32, delayed: bool): bool =
      var tmpDt = dt
      sendEvent(EVENT_UPDATE, addr tmpDt)

    proc Draw(ctx: GraphicsContext) =
      var tmpCtx = ctx
      sendEvent(EVENT_DRAW, addr tmpCtx)
      finishDraw()
      sendEvent(EVENT_DRAW_UI, addr tmpCtx)
    
    proc gameClose() =
      sendEvent(EVENT_CLOSE, nil)
