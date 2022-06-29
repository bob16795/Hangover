createEvent(EVENT_MOUSE_MOVE)
createEvent(EVENT_MOUSE_CLICK)
createEvent(EVENT_MOUSE_RELEASE)

when not defined(ginGLFM):
  proc mouseMoveCb*(win: Window, res: tuple[x, y: float64]) =
    var pos = res
    pos.x += textureOffset.x
    pos.y += textureOffset.y
    sendEvent(EVENT_MOUSE_MOVE, addr pos)
  
  proc mouseButtonCb*(win: Window, button: MouseButton, action: bool, mods: set[ModifierKey]) =
    var btn = ord(button)
    if action:
      sendEvent(EVENT_MOUSE_CLICK, addr btn)
    else:
      sendEvent(EVENT_MOUSE_RELEASE, addr btn)
