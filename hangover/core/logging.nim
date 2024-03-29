import streams
import strformat
import strutils

type
  LogPriority* = enum
    ## the priority of a log
    lpTrace
    lpDebug
    lpInfo
    lpWarn
    lpError
    lpCrit

  Logger* = object
    ## logs events
    priority: LogPriority
    output*: StreaM
    fileOutput: bool

method enableFileOutput(l: var Logger) =
  l.output = newFileStream("hangover.log", fmWrite)
  l.fileOutput = true

proc newLogger(priority: LogPriority = lpInfo): Logger =
  when defined debug:
    result.priority = lpDebug
  else:
    result.priority = priority 
  result.enableFileOutput()

var
  logger = newLogger()

method `priority=`*(l: var Logger, priority: LogPriority) =
  l.priority = priority

proc `android_log_print`(st: cint, src: cstring, data: cstring) {.importc: "__android_log_print".}

method log*(l: Logger, priority: LogPriority, file, message: string) =
  let pString = case priority:
    of lpTrace: "TRACE"
    of lpDebug: "DEBUG"
    of lpInfo:  "INFO"
    of lpWarn:  "WARN"
    of lpError: "ERROR"
    of lpCrit:  "CRITICAL"
  when defined ginGLFM:
    android_log_print 4, "HANGOVER", cstring(&"[{pString}] {file}: {message}")

    return
  if priority >= l.priority:
    echo &"[{pString}] {file}: {message}"

  if l.fileOutput:
    l.output.write(&"[{pString}] {file}: {message}\n")
    l.output.flush()


template LOG_TRACE*(file: string, message: varargs[string, `$`]) = logger.log(lpTrace, file, message.join(" "))
template LOG_DEBUG*(file: string, message: varargs[string, `$`]) = logger.log(lpDebug, file, message.join(" "))
template LOG_INFO*(file: string, message: varargs[string, `$`]) = logger.log(lpInfo, file, message.join(" "))
template LOG_WARN*(file: string, message: varargs[string, `$`]) = logger.log(lpWarn, file, message.join(" "))
template LOG_ERROR*(file: string, message: varargs[string, `$`]) = logger.log(lpError, file, message.join(" "))
template LOG_CRITICAL*(file: string, message: varargs[string, `$`]) = logger.log(lpCrit, file, message.join(" "))
