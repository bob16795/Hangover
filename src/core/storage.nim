import os
import strutils
import strformat

var APPNAME*: string

proc getContentDir*(): string =
    return getConfigDir() / APPNAME

proc getFullFilePath*(file: string): string =
    if not file.contains("://"):
        echo &"BAD PATH: {file}"
        quit(1)
    case file.split("://")[0]:
    of "cont", "content":
        return getAppDir() / "content" / file.split("://")[1]
    of "res", "resources":
        return getContentDir() / file.split("://")[1]
