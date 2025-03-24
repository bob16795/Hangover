from glfw import pollEvents, shouldClose
import audio
import hangover/core/types/font
import hangover/core/types/appdata
import hangover/core/types/point
import hangover/core/loop
import hangover/core/events
import sugar
import segfaults
import asyncdispatch
import times
import locks
import options
import strformat
import strutils

export formatFloat
export asyncdispatch
export loop

when defined debug:
  import console

## templates:
## creates a game loop
type
  LoadDrawEventData* = ref object
    statusText*: string
    statusPercent*: float32
    size*: Point
    done*: bool

  LoadStatusEventData* = object
    percent*: float32
    name*: string
    prev*: Option[string]


createEvent[LoadDrawEventData] eventDrawLoad, {hideLogs, sendOnCrash}
createEvent[LoadStatusEventData] eventLoadStatus
createEvent[void] eventInitialize

createEvent[float32] eventUpdate, {hideLogs, sendOnCrash} 
createEvent[float32] eventFixedUpdate, {hideLogs, sendOnCrash} 
createEvent[float32] eventDraw, {hideLogs}
createEvent[void] eventDrawUi, {hideLogs} 
createEvent[void] eventLoaded 
createEvent[void] eventClose, {sendOnCrash}

const ginSourcePath {.strdefine.} = ""
const ginNimblePath {.strdefine.} = ""

var mainLoop*: Loop

template runGame*(data: AppData = newAppData()) =
  ## the main loop of a game
  var
    pc: float
    loadStatus: string
    uiDrawn: bool
    size = data.size
    ctx: GraphicsContext

  mainLoop = newLoop(60)

  ctx = initGraphics(data)

  eventResize.listen do (newSize: Point) -> bool:
    size = newSize

  eventDrawUi.listen do () -> bool:
    if uiDrawn: return

    drawUI()
    uiDrawn = true

  var lastTime {.gensym.}: float

  eventLoadStatus.listen do (status: LoadStatusEventData) -> bool:
    if status.prev.isSome():
      let newTime = cpuTime()
      let time = newTime - lastTime
      let stepName = status.prev.get()
      LOG_TRACE "ho->templates", "Finished " & stepName & " in " & formatFloat(time, ffDecimal, 9) & "s"
      lastTime = newTime

    pc = status.percent
    loadStatus = status.name

  var loadLock: Lock
  var started: bool
  var crashed: bool

  loadLock.initLock()

  proc initThread() {.thread.} =
    try:
      let loadStartTime = cpuTime()
      lastTime = loadStartTime
      withLock loadLock:
        started = true
        eventInitialize.send
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
      var loadData = LoadDrawEventData(
        statusText: loadStatus, 
        statusPercent: pc,
        size: size,
      ) 
      eventDrawLoad.send loadData

      if (loadData.done or crashed) and tryAcquire(loadLock):
        finishDraw()
        finishRender(ctx)
        loadLock.release()
        return
      when not defined(ginGLFM):
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          quit()
      finishDraw()
      finishRender(ctx)
      updateAudio(1.0 / 60.0)
      await sleepAsync(1000.0 / 60.0)

  try:
    LOG_TRACE("ho->templates", "start loading game")

    initFT()
    initAudio()
    initUIManager(data.size)

    setupEventCallbacks(ctx)

    waitFor drawLoadingAsync()
    
    eventClose.listen do () -> bool:
      mainLoop.done = true

    eventResize.listen do (_: Point) -> bool:
      mainLoop.forceDraw(ctx)
      mainLoop.updateFPS()

    #createListener(EVENT_RESIZE_DONE, proc(p: pointer): bool = mainLoop.forceDraw(ctx))

    mainLoop.fixedUpdateProc =
      proc (dt: float) =
        eventFixedUpdate.send dt

    mainLoop.updateProc =
      proc (dt: float, delayed: bool) =
        glfw.pollEvents()
        if glfw.shouldClose(ctx.window):
          eventClose.send

        updateUI(dt)
        updateAudio(dt)
        eventUpdate.send dt

    mainLoop.drawProc = proc (ctx: var GraphicsContext, dt: float32) =
      eventDraw.send dt
      eventDrawUI.send

      finishrender(ctx)
      uiDrawn = false

    while not mainLoop.done:
      mainLoop.update(ctx)

  except Exception as ex:
    when not declared drawCrash:
      raise ex
    else:
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

      mainLoop.fixedUpdateProc = nil

      mainLoop.drawProc =
        proc (ctx: var GraphicsContext, dt: float32) =
          drawCrash(ctx, e, defect)

          finishrender(ctx)

      mainLoop.updateProc =
        proc (dt: float, delayed: bool) =
          glfw.pollEvents()

          if glfw.shouldClose(ctx.window) or ctx.window.isKeyDown(keyEscape):
            eventClose.send

      while not mainLoop.done:
        mainLoop.update(ctx)
  finally:
    deinitFT()
  
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
