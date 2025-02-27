import unicode

createEvent[Key] eventPressKey, {hideLogs} 
createEvent[Key] eventReleaseKey, {hideLogs}
createEvent[string] eventUpdateLineEnter
createEvent[void] eventStartLineEnter
createEvent[void] eventStopLineEnter
createEvent[string] eventSetLineEnter
createEvent[Rune] eventPressChar, {hideLogs}

var
  lineInput = false
  lineInputNew = false
  lineText = ""

when not defined(ginGLFM):
  var keyMods*: set[ModifierKey]
  
  proc keyCb*(win: Window, key: Key, scanCode: int32, action: KeyAction,
      mods: set[ModifierKey]) =
    keyMods = mods
    if lineInput:
      if action != kaUp and key == keyBackspace and lineText != "":
        lineText = lineText[0..^2]
        eventUpdateLineEnter.send(lineText)
    case action:
    of kaDown:
      eventPressKey.send(key)
    of kaUp:
      eventReleaseKey.send(key)
    else:
      discard
  
  proc charCb*(win: Window, r: Rune) =
    eventPressChar.send(r)

    if not lineInput: return

    lineText &= $r
    eventUpdateLineEnter.send(lineText)
  
proc setLineText*(data: string): bool =
  lineText = data
