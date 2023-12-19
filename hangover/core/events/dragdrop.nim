when not defined(ginGLFM):
  createEvent(EVENT_DROP_FILE)
  
  proc dropCb(win: Window, paths: PathDropInfo) =
    for p in paths:
      let path = p
      sendEvent(EVENT_DROP_FILE, addr path)
