import unicode

createEvent(EVENT_PRESS_KEY, true)
createEvent(EVENT_RELEASE_KEY, true)
createEvent(EVENT_LINE_ENTER)
createEvent(EVENT_START_LINE_ENTER)
createEvent(EVENT_STOP_LINE_ENTER)
createEvent(EVENT_SET_LINE_TEXT)

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
        sendEvent(EVENT_LINE_ENTER, addr lineText)
    case action:
    of kaDown:
      var k = key
      sendEvent(EVENT_PRESS_KEY, addr k)
    of kaUp:
      var k = key
      sendEvent(EVENT_RELEASE_KEY, addr k)
    else:
      discard
  
  proc charCb*(win: Window, r: Rune) =
    if lineInput == false or not lineInputNew:
      lineInputNew = lineInput
      return
    lineText &= $r
    sendEvent(EVENT_LINE_ENTER, addr lineText)
  
proc setLineText*(data: pointer): bool =
  lineText = cast[ptr string](data)[]

