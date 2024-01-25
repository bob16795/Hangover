import os
import strutils
import strformat
when defined(ginGLFM):
  import glfm

#TODO: register custom paths

var
  APPNAME*: string
  ## set to change the app name in storage

proc getContentDir*(): string =
  ## gets the path of cont://
  when defined(ginGLFM):
    return $glfmBundleDir()
  return getConfigDir() / APPNAME

proc hoPath*(file: string): string =
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

  # error from invalid path
  var e: ref OSError
  new(e)
  e.msg = &"Invalid File Path '{file}'"
  raise e

proc getFullFilePath*(file: string): string {.deprecated.} =
  file.hoPath
