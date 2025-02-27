import hangover/rendering/shapes
import types/rect
import types/font
import types/vector2
import types/color
import algorithm
import strutils
import unicode
import tables
import sequtils
import hangover/core/logging
import hangover/core/types/texture
import options

type
  ConsoleCommand* = object
    help: string
    runs: proc(s: seq[string]): string
  
  ConsoleLine* = object
    priority: LogPriority
    text: string

  DebugConsole* = ref object of LoggerConsole
    show*: bool
    font*: Font
    text*: seq[ConsoleLine]
    input: string
    inputIndex: int
    bounds*: Rect
    commands: Table[string, ConsoleCommand]
    scroll: float32
    history: seq[string]
    history_id: int
    time: int
    max: float32

const ginSourcePath {.strdefine.} = ""
const ginNimblePath {.strdefine.} = ""
const ginAppName {.strdefine.} = "Hangover Game"

method log*(console: DebugConsole, text: string, priority: LogPriority) =
  console.text &= ConsoleLine(
    text: text,
    priority: priority,
  )

proc scroll*(console: var DebugConsole, offset: float32) =
  console.scroll += offset
  console.scroll = console.scroll.clamp(0, console.max)

proc newDebugConsole*(): DebugConsole =
  result = DebugConsole()

proc hist*(console: var DebugConsole, offset: int) =
  console.history_id += offset
  console.history_id = console.history_id.clamp(0, console.history.len)
  console.input = if console.history_id == 0:
    ""
  else:
    console.history[^console.history_id]
  console.inputIndex = console.input.len
  console.scroll = 0
  console.time = 0

proc move*(console: var DebugConsole, offset: int) =
  console.inputIndex += offset
  console.inputIndex = console.inputIndex.clamp(0, console.input.len)
  console.time = 0

proc enter*(console: var DebugConsole) =
  if not console.show: return
  
  console.scroll = 0

  if strutils.strip(console.input).len == 0:
    return

  console.history &= console.input 
  console.history_id = 0
  console.inputIndex = 0
  console.time = 0

  let input = console.input
  console.input = ""

  console.text &= ConsoleLine(
    text: ">>> " & input,
    priority: lpInfo,
  )

  var full_cmd = input.split(" ")
  full_cmd.keepItIf(it.len > 0)
  let cmd = if full_cmd.len > 0:
      full_cmd[0]
    else:
      ""

  if cmd in ["clear", "cls"]:
    console.text = @[]
    return
  if cmd == "help":
    for k in console.commands.keys():
      var sp = 20 - len(k)
      console.text &= ConsoleLine(
        text: k & "\t- " & console.commands[k].help,
        priority: lpInfo,
      )
    return

  if cmd in console.commands:
    try:
      let lines = console.commands[cmd].runs(full_cmd[1..^1]).split("\n").filterIt(strutils.strip(it).len > 0)
      for l in lines:
        console.text &= ConsoleLine(
          text: l,
          priority: lpInfo,
        )
    except Exception as ex:
      console.text &= ConsoleLine(
        priority: lpError,
        text: "Error Running Command: " & ex.msg,
      )

      for line in ex.getStackTrace().split("\n"):
        if line == "": continue

        var tmp = line 

        tmp = tmp
          .replace(ginSourcePath, "[" & ginAppName & "]/")
          .replace("/home/john/.choosenim/toolchains/nim-2.2.0/lib/", "[Stdl]/")
        if tmp.startsWith(ginNimblePath):
          let
            tt = tmp[ginNimblePath.len..^1].split("/")
            package = tt[0].split("-")
          tmp = tmp.replace(ginNimblePath & tt[0], "[Pakg]/" & package[0] & "V" & package[1])
           
        console.text &= ConsoleLine(
          priority: lpTrace,
          text: "  " & tmp
        )
        
    return

  console.text &= ConsoleLine(
    priority: lpError,
    text: "Error: Command Not Found",
  )

proc back*(console: var DebugConsole, backSpace: bool) =
  if not console.show: return
  console.scroll = 0

  if backSpace:
    if console.inputIndex != 0:
      console.inputIndex -= 1
      console.input.delete(console.inputIndex..console.inputIndex)
  else:
    if console.inputIndex < console.input.len:
      console.input.delete(console.inputIndex..console.inputIndex)

proc addConsoleCommand*(console: var DebugConsole, name: string, help: string, runs: proc(s: seq[string]): string) =
  console.commands[name] = ConsoleCommand(
    help: help,
    runs: runs,
  )

proc add*(console: var DebugConsole, c: Rune) =
  if c == Rune('`'):
    console.show = not console.show
    return

  if not console.show: return
  
  console.scroll = 0
  console.input.insert($c, console.inputIndex)
  console.inputIndex += 1
  console.time = 0

proc draw*(console: DebugConsole) =
  if not console.show: return
    
  drawRectFill(console.bounds, newColor(0, 0, 0, 200), contrast = ContrastEntry(mode: bg))
  drawRectOutline(console.bounds, 2, newColor(255, 255, 255), contrast = ContrastEntry(mode: fg))

  drawRectOutline(
    newRect(
      console.bounds.x,
      console.bounds.y + console.bounds.height - console.font.size.float32 - 30,
      console.bounds.width,
      console.font.size.float32 + 30,
    ),
    2,
    newColor(255, 255, 255),
    contrast = ContrastEntry(mode: fg),
  )

  let newBounds = newRect(
    console.bounds.x + 10,
    console.bounds.y + 10,
    console.bounds.width - 30 - 20,
    console.bounds.height - console.font.size.float - 30 - 20,
  )

  console.time += 1

  let input_y = console.bounds.y + console.bounds.height - console.font.size.float - 15
  console.font.draw(">>> " & console.input, newVector2(20, input_y), newColor(255, 255, 255, 255))

  let bar_x = console.font.sizeText(">>> " & console.input[0..<console.inputIndex]).x + 17
  drawRectFill(
    newRect(
      bar_x,
      input_y, 
      3,
      console.font.size.float,
    ),
    newColor(255, 255, 255, if console.time mod 60 < 30: 255 else: 0)
  )

  withScissor newBounds:
    var y = min(newBounds.y, newBounds.y + newBounds.height - console.text.len.float32 * console.font.size.float32)
    console.max = abs(y - newBounds.y)
    y += console.scroll

    for l in console.text:
      let color = case l.priority:
        of lpTrace: newColorGray(150)
        of lpDebug: newColorGray(200)
        of lpInfo: COLOR_WHITE
        of lpWarn: COLOR_YELLOW
        of lpError: COLOR_RED
        of lpCrit: COLOR_CYAN

      var x = console.bounds.x
      for tmp in l.text.split("\t"):
        console.font.draw(tmp, newVector2(20 + x, y), color)
        x += 300
      y += console.font.size.float

  let
    scrollBounds = newRect(
      console.bounds.x + console.bounds.width - 30,
      console.bounds.y,
      30,
      console.bounds.height - 28 - console.font.size.float32,
    )

    scrollHeight = max(50, scrollBounds.height / float32(console.max / scrollBounds.height + 1))

    scrollPc = 1.0 - (if console.max == 0:
      1.0.float32
    else:
      console.scroll / console.max)

    handleBounds = newRect(
      scrollBounds.x,
      scrollBounds.y + (scrollBounds.height - scrollHeight) * scrollPc,
      scrollBounds.width,
      scrollHeight,
    )

  drawRectOutline(scrollBounds, 2, newColor(255, 255, 255), contrast = ContrastEntry(mode: fg))
  drawRectFill(handleBounds, newColor(255, 255, 255), contrast = ContrastEntry(mode: fg))
