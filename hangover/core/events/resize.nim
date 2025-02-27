createEvent[Point] eventResize, {sendOnCrash}
createEvent[Point] eventResizeFramebuffer, {sendOnCrash} 
createEvent[bool] eventFocus

#TODO: comment

when not defined(ginGLFM):
  proc sizeCB*(win: Window, res: tuple[w, h: int32]) =
    ## Called when the window is resized
    eventResize.send(newPoint(res.w, res.h))
  
  proc resizeCB*(win: Window, res: tuple[w, h: int32]) =
    eventResizeFramebuffer.send(newPoint(res.w, res.h))

  proc focusCB*(win: Window, focused: bool) =
    eventFocus.send(focused)
