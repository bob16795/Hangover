createEvent(EVENT_PRESS_KEY)
createEvent(EVENT_RELEASE_KEY)

proc keyCb*(win: Window, key: Key, scanCode: int32, action: KeyAction,
    mods: set[ModifierKey]) =
  case action:
  of kaDown:
    var k = key
    sendEvent(EVENT_PRESS_KEY, addr k)
  of kaUp:
    var k = key
    sendEvent(EVENT_RELEASE_KEY, addr k)
  else:
    discard
