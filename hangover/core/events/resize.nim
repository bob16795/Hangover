createEvent(EVENT_RESIZE)
createEvent(EVENT_RESIZE_FRAMEBUFFER)
createEvent(EVENT_FOCUS)

let
  EVENT_RESIZE_DONE* {.deprecated.} = EVENT_RESIZE_FRAMEBUFFER

#TODO: comment

when not defined(ginGLFM):
  proc sizeCB*(win: Window, res: tuple[w, h: int32]) =
    ## Called when the window is resized
    sendEvent(EVENT_RESIZE, addr res)
  
  proc resizeCB*(win: Window, res: tuple[w, h: int32]) =
    sendEvent(EVENT_RESIZE_DONE, addr res)

  proc focusCB*(win: Window, focused: bool) =
    sendEvent(EVENT_FOCUS, addr focused)
