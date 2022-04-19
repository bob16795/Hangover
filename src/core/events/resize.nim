createEvent(EVENT_RESIZE)

proc resizeCB*(win: Window, res: tuple[w, h: int32]) =
  var r = res
  sendEvent(EVENT_RESIZE, addr r)
