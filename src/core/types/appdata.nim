import point

import os

import strformat
import system

type
  AppData* = object
    ## stores data for an app
    name*: string
    size*: Point
    aa*: int

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
  discard staticExec(&"/bin/bash {rcGen} 0-0-0-0 '{ginAppName}' '{ginIcon}' {tmpRc}")
  when system.hostCPU == "i386":
    discard staticExec(&"i686-w64-mingw32-windres {tmpRc} -O coff {tmpRes32}")
    {.passl: tmpRes32.}
  when system.hostCPU == "amd64":
    discard staticExec(&"x86_64-w64-mingw32-windres {tmpRc} -O coff {tmpRes64}")
    {.passl: tmpRes64.}

proc newAppData*(): AppData =
  ## creates a new app data for game setup
  result.name = ginAppName
  result.size = newPoint(640, 480)
  result.aa = 0
