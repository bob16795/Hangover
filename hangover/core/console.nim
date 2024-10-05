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
import options

type
  ConsoleCommand* = proc(s: seq[string]): string

type
  DebugConsole* = ref object of LoggerConsole
    show*: bool
    font*: Font
    text*: seq[string]
    bounds*: Rect
    commands*: Table[string, ConsoleCommand]

method log*(console: var DebugConsole, text: string) =
  let
    last = console.text[^1]
  console.text = console.text[0..^2]
  console.text &= text
  console.text &= last

proc newDebugConsole*(): DebugConsole =
  result = DebugConsole()

proc enter*(console: var DebugConsole) =
  if not console.show: return

  var full_cmd = console.text[^1].split(" ")
  full_cmd.keepItIf(it.len > 0)
  console.text[^1] = ">>> " & console.text[^1]
  let cmd = full_cmd[0]
  if cmd == "clear":
    console.text = @[""]
    return
  if cmd == "help":
    console.text &= ""
    for k in console.commands.keys():
      console.text[^1] &= k & " "
    console.text &= ""
    return

  if cmd in console.commands:
    try:
      console.text &= console.commands[cmd](full_cmd[1..^1]).split("\n")
    except Exception as ex:
      console.text &= "Error Running Command: " & $(ex[])
    console.text &= ""
    return
  console.text &= "Command Not Found"
  console.text &= ""

proc back*(console: var DebugConsole) =
  if not console.show: return

  if console.text[^1].len != 0:
    console.text[^1] = console.text[^1][0..^2]

proc add*(console: var DebugConsole, c: Rune) =
  if c == Rune('`'):
    console.show = not console.show
    return
  if not console.show: return

  console.text[^1] &= c

proc draw*(console: DebugConsole) =
  if not console.show: return

  drawRectFill(console.bounds, newColor(0, 0, 0, 200), fg = some(false))
  var y = min(float(console.text.len) * console.font.size.float, console.bounds.height - console.font.size.float)
  var first = true
  for l in console.text.reversed():
    if first:
      console.font.draw(">>> " & l, newVector2(20, y), newColor(255, 255, 255, 255))
      first = false
    else:
      console.font.draw(l, newVector2(20, y), newColor(255, 255, 255, 255))
    y -= console.font.size.float
