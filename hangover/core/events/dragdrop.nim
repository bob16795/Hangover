createEvent[string] eventDropFile

proc dropCb(win: Window, paths: PathDropInfo) =
  for path in paths:
    eventDropFile.send($path)
