createEvent(EVENT_MOUSE_MOVE)
createEvent(EVENT_MOUSE_CLICK)
createEvent(EVENT_MOUSE_RELEASE)

proc mouseMoveCb*(win: Window, res: tuple[x, y: float64]) =
  var pos = res
  sendEvent(EVENT_MOUSE_MOVE, addr pos)

proc mouseButtonCb*(win: Window, button: MouseButton, action: bool, mods: set[ModifierKey]) =
  var btn = ord(button)
  if action:
    sendEvent(EVENT_MOUSE_CLICK, addr btn)
  else:
    sendEvent(EVENT_MOUSE_RELEASE, addr btn)
