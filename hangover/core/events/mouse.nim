createEvent[Vector2] eventMouseMove, {hideLogs}
createEvent[int] eventMouseClick, {hideLogs}
createEvent[int] eventMouseRelease, {hideLogs}
createEvent[Vector2] eventMouseScroll, {hideLogs}

# TODO: comment

when not defined(ginGLFM):
  proc mouseMoveCb*(win: Window, res: tuple[x, y: float64]) =
    var pos = res
    pos.x += textureOffset.x
    pos.y += textureOffset.y
    eventMouseMove.send(newVector2(pos.x, pos.y))
  
  proc mouseButtonCb*(win: Window, button: MouseButton, action: bool, mods: set[ModifierKey]) =
    let btn = ord(button)
    if action:
      eventMouseClick.send(btn)
    else:
      eventMouseRelease.send(btn)

  proc mouseScrollCb*(win: Window, res: tuple[x, y: float64]) =
    eventMouseScroll.send(newVector2(res.x, res.y))
