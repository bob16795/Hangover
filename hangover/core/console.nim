import types/font
import types/vector2
import types/color
import opengl
import algorithm
import strutils
import unicode
import tables

type
  ConsoleCommand = proc(s: seq[string]): string

var
  debugConsole*: bool
  consoleFont*: ptr Font
  consoleText: seq[string] = @[""]
  consoleCommands*: Table[string, ConsoleCommand]

proc updateConsole*() =
  discard

proc runConsole*() =
  let full_cmd = consoleText[^1].split(" ")
  let cmd = full_cmd[0]
  if cmd == "clear":
    consoleText = @[""]
    return
  if cmd == "help":
    consoleText &= ""
    for k in consoleCommands.keys():
      consoleText[^1] &= k & " "
    consoleText &= ""
    return

  if cmd in consoleCommands:
    try:
      consoleText &= consoleCommands[cmd](full_cmd[1..^1]).split("\n")
    except Exception as ex:
      consoleText &= "Error Running Command: " & $(ex[])
    consoleText &= ""
    return
  consoleText &= "Command Not Found"
  consoleText &= ""

proc consoleBack*() =
  if consoleText[^1].len != 0:
    consoleText[^1] = consoleText[^1][0..^2]

proc consoleChar*(c: Rune) =
  if c == Rune('`'): return
  consoleText[^1] &= c

proc drawConsole*() =
  var y = float(consoleText.len) * consoleFont.size.float
  for l in consoleText.reversed():
    consoleFont[].draw(l, newVector2(20, y), newColor(255, 255, 255, 255))
    y -= consoleFont.size.float
