import point
import color
import os
import system
import strformat
#import syncio

type
  AppData* = object
    ## stores data for an app
    name*: string
    size*: Point
    aa*: int
    color*: Color

const
  ginAppName {.strdefine.} = "Hangover Game"

static:
  # get misc data
  const
    tmp = getTempDir() & "/hangover"
    ginIcon {.strdefine.}: string = staticExec("nimble path hangover") & "/hangover/assets/icon.ico"
    rcGen = staticExec("nimble path hangover") & "/hangover/assets/rcgen.sh"
    tmpRc = tmp & "/gingame.rc"
    tmpRes32 = tmp & "/gingame32.res"
    tmpRes64 = tmp & "/gingame64.res"

  # create a res file and gen an icon
  when defined(windows):
    echo staticExec(&"mkdir -p {tmp}")
    echo staticExec(&"bash {rcGen} 0-0-0-0 '{ginAppName}' '{ginIcon}' {tmpRc}")
    when system.hostCPU == "i386":
      echo staticExec(&"i686-w64-mingw32-windres {tmpRc} -O coff {tmpRes32}")
      {.passl: tmpRes32.}
    when system.hostCPU == "amd64":
      echo staticExec(&"x86_64-w64-mingw32-windres {tmpRc} -O coff {tmpRes64}")
      {.passl: tmpRes64.}

proc newAppData*(): AppData =
  ## creates a new app data for game setup
  result.name = ginAppName
  result.size = newPoint(640, 480)
  result.aa = 0
