when defined(ginGLFM):
  import glfm
else:
  from glfw import pollEvents, shouldClose
  import audio
import hangover/core/types/font
import hangover/core/loop
import hangover/core/events
import sugar
import segfaults
import asyncdispatch
import times
import locks
import options
import strformat

export loop

export asyncdispatch

when defined debug:
  import console

## templates:
## creates a game loop

createEvent[void] eventUpdate, {hideLogs} 
createEvent[void] eventDraw 
createEvent[void] eventDrawUi 
createEvent[void] eventInit
createEvent[void] eventLoaded 
createEvent[void] eventClose

const ginSourcePath {.strdefine.} = ""
const ginNimblePath {.strdefine.} = ""

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

  eventResize.listen do (newSize: Point) -> bool:
    size = newSize

  template noUI() = ui = false
  template drawUIEarly() =
    if ui:
      drawUI()
      ui = false

  var lastTime {.gensym.}: float

  template setStatus(
    perc: float32, status: string,
    timeUpdate: Option[string] = none[string](),
  ): untyped =
    if timeUpdate.isSome():
      let newTime = cpuTime()
      let time = newTime - lastTime
      let stepName = timeUpdate.get()
      LOG_TRACE "ho->templates", "Finished " & stepName & " in " & formatFloat(time, ffDecimal, 9) & "s"
      lastTime = newTime

    pc = perc
    loadStatus = status

  body

  var loadLock: Lock
  var started: bool
  var crashed: bool

  loadLock.initLock()

  proc initThread() {.thread.} =
    {.cast(gcsafe).}:
      try:
        let loadStartTime = cpuTime()
        lastTime = loadStartTime
        withLock loadLock:
          started = true
          initialize()
        let time = cpuTime() - loadStartTime
        LOG_TRACE "ho->templates", "Loaded game in " & formatFloat(time, ffDecimal, 9) & "s"
      except Exception as ex:
        LOG_CRITICAL "ho->templates", ex.msg
        raise ex

  proc drawLoadingAsync() {.async.} =
    var tmp: Thread[void]
    createThread(tmp, initThread)
    
    while not started:
      await sleepAsync(1000.0 / 60.0)

    while true:
      if (drawLoading(pc, loadStatus, ctx, size) or crashed) and tryAcquire(loadLock):
        finishDraw()
        finishRender(ctx)
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

  # proc demangleWord(s: string, idx: var int): string =
  #   let start = idx

  #   case s[idx]
  #   of '0'..'9': 
  #     var len = 0
  #     while s[idx] in '0'..'9':
  #       len *= 10
  #       len += int(s[idx]) - int('0')
  #       idx += 1
  #     result = s[idx..(idx + len - 1)]
  #     idx += len

  #     if result[^1] == '_':
  #       result = result[0..^2].replace("colon", ":")
  #   of 'N':
  #     idx += 1
  #     result = demangleWord(s, idx) & "." & demangleWord(s, idx)
  #     idx += 1
  #   of 'I':
  #     idx += 1
  #     result = "["
  #     var hasFirst = false
  #     while s[idx] != 'E':
  #       let tmp = demangleWord(s, idx)
  #       if hasFirst:
  #         if tmp[0] != '[':
  #           result &= ", "
  #       else:
  #         hasFirst = true

  #       result &= tmp
  #     result &= "]"
  #     idx += 1
  #   else:
  #     idx += 1
  #     result = demangleWord(s, idx)

  #   echo result

  # # _ZN4loop6updateE3varIN4loop4LoopEE3varI3refIN4loop31GraphicsContextcolonObjectType_EEE
  # # loop.update(var[loop.Loop], var[ref[loop.GraphicsContext:ObjectType]])

  # proc demangleZ(s: string): string =
  #   if s == "":
  #     return ""

  #   echo s

  #   var idx = 0

  #   result = demangleWord(s, idx) & "("
  #   var hasFirst = false
  #   while idx < s.len:
  #     let tmp = demangleWord(s, idx)
  #     if hasFirst:
  #       if tmp[0] != '[':
  #         result &= ", "
  #     else:
  #       hasFirst = true

  #     result &= tmp
  # 
  #   result &= ")"

  try:
    LOG_TRACE("ho->templates", "start loading game")

    initFT()
    initAudio()
    initUIManager(data.size)

    setupEventCallbacks(ctx)

    waitFor drawLoadingAsync()

    eventResize.listen do (_: Point) -> bool:
      mainLoop.forceDraw(ctx)
      mainLoop.updateFPS()

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

    while not mainLoop.done:
      mainLoop.update(ctx)

  except Exception as ex:
    pauseAudio()

    eventsCrashed = true

    var stacktrace = ""
    var inputTrace = ex.getStackTrace()
    for line in inputTrace.split("\n"):
      var tmp = line
      # if line.split(" ")[^1][0] == '/':
      #   stacktrace &= "\n> ..... oops"
      #   break

      tmp = tmp
        .replace(ginSourcePath, "[" & ginAppName & "]/")
        .replace("/home/john/.choosenim/toolchains/nim-2.2.0/lib/", "[Stdl]/")
      if tmp.startsWith(ginNimblePath):
        let
          tt = tmp[ginNimblePath.len..^1].split("/")
          package = tt[0].split("-")
        tmp = tmp.replace(ginNimblePath & tt[0], "[Pakg]/" & package[0] & "V" & package[1])
         
      if stacktrace != "":
        stacktrace &= "\n"

      stacktrace &= "> " & tmp

    let
      defect = ex of Defect
      message = ex.msg
        .replace(ginSourcePath, "[" & ginAppName & "]/")
        .replace("/home/john/.choosenim/toolchains/nim-2.2.0/lib/", "[Stdl]/")
      e =
        ginAppName & " has crashed!\n" &
        "Press escape to close the game, If the problem persists please report it.\n" &
        "\n" &
        "Error Message:\n" &
          "> " & $ex.name & ": " & message & "\n" &
        "\n" &
        "StackTrace:\n" &
        stacktrace
   
    for l in e.split("\n"):
      LOG_CRITICAL "ho->templates", l

    mainLoop.drawProc =
      proc (ctx: var GraphicsContext, dt: float32) =
        drawCrash(ctx, e, defect)

        finishrender(ctx)

    mainLoop.fixedUpdateProc = nil

    mainLoop.updateProc =
      proc (dt: float, delayed: bool): bool =
        glfw.pollEvents()

        return glfw.shouldClose(ctx.window) or
          ctx.window.isKeyDown(keyEscape)

    while not mainLoop.done:
      mainLoop.update(ctx)

  finally:
    deinitFT()
    gameClose()
  
template GameECS*(name: string, body: untyped) =
  import hangover/ecs/types
  import hangover/ecs/entity

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
