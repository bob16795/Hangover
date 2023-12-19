createEvent(EVENT_MOUSE_MOVE, true)
createEvent(EVENT_MOUSE_CLICK, true)
createEvent(EVENT_MOUSE_RELEASE, true)
createEvent(EVENT_MOUSE_SCROLL, true)

# TODO: comment

when not defined(ginGLFM):
  proc mouseMoveCb*(win: Window, res: tuple[x, y: float64]) =
    var pos = res
    pos.x += textureOffset.x
    pos.y += textureOffset.y
    sendEvent(EVENT_MOUSE_MOVE, addr pos)
  
  proc mouseButtonCb*(win: Window, button: MouseButton, action: bool, mods: set[ModifierKey]) =
    let btn = ord(button)
    if action:
      sendEvent(EVENT_MOUSE_CLICK, addr btn)
    else:
      sendEvent(EVENT_MOUSE_RELEASE, addr btn)

  proc mouseScrollCb*(win: Window, res: tuple[x, y: float64]) =
    let offset = newVector2(res.x, res.y)

    sendEvent(EVENT_MOUSE_SCROLL, addr offset)
