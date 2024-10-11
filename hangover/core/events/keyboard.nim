import unicode

createEvent(EVENT_PRESS_KEY, true)
createEvent(EVENT_RELEASE_KEY, true)
createEvent(EVENT_LINE_ENTER)
createEvent(EVENT_START_LINE_ENTER)
createEvent(EVENT_STOP_LINE_ENTER)
createEvent(EVENT_SET_LINE_TEXT)
createEvent(EVENT_CHAR)

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
      let k = key
      sendEvent(EVENT_PRESS_KEY, addr k)
    of kaUp:
      let k = key
      sendEvent(EVENT_RELEASE_KEY, addr k)
    else:
      discard
  
  proc charCb*(win: Window, r: Rune) =
    sendEvent(EVENT_CHAR, addr r)

    if not lineInput: return

    lineText &= $r
    sendEvent(EVENT_LINE_ENTER, addr lineText)
  
proc setLineText*(data: pointer): bool {.cdecl.} =
  lineText = cast[ptr string](data)[]

