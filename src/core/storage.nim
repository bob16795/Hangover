import os
import strutils
import strformat

var
  APPNAME*: string
  ## set to change the app name in storage

proc getContentDir*(): string =
  ## gets the path of cont://
  return getConfigDir() / APPNAME

proc getFullFilePath*(file: string): string =
  ## expands a file path
  if not file.contains("://"):
    var e: ref OSError
    new(e)
    e.msg = &"Invalid File Path '{file}'"
    raise e
  case file.split("://")[0]:
  of "cont", "content":
    return getAppDir() / "content" / file.split("://")[1]
  of "res", "resources":
    return getContentDir() / file.split("://")[1]
  var e: ref OSError
  new(e)
  e.msg = &"Invalid File Path '{file}'"
  raise e
