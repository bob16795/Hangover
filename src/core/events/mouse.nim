createEvent(EVENT_MOUSE_MOVE)

proc mouseMoveCb*(win: Window, res: tuple[x, y: float64]) =
  var pos = res
  sendEvent(EVENT_MOUSE_MOVE, addr pos)
