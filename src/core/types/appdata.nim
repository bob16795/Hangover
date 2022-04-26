import point

import os

import strformat
import system

type
  AppData* = object
    name*: string
    size*: Point

const
  tmp = getTempDir() & "/gin2"
  ginIcon {.strdefine.}: string = staticExec("nimble path gin2") & "/assets/icon.ico"
  ginAppName {.strdefine.} = "Gin Game"
  rcGen = staticExec("nimble path gin2") & "/assets/rcgen.sh"
  tmpRc = tmp & "/gingame.rc"
  tmpRes32 = tmp & "/gingame32.res"
  tmpRes64 = tmp & "/gingame64.res"

static:
  discard staticExec(&"mkdir {tmp}")
  echo staticExec(&"/bin/bash {rcGen} 0-0-0-0 '{ginAppName}' '{ginIcon}' {tmpRc}")
  when system.hostCPU == "i386":
    echo staticExec(&"i686-w64-mingw32-windres {tmpRc} -O coff {tmpRes32}")
    {.passl: tmpRes32.}
  when system.hostCPU == "amd64":
    echo staticExec(&"x86_64-w64-mingw32-windres {tmpRc} -O coff {tmpRes64}")
    {.passl: tmpRes64.}

proc newAppData*(): AppData =
  result.name = ginAppName
  result.size = newPoint(640, 480)
