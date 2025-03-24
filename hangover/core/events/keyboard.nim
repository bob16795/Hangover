import unicode
import locks
import atomics

createEvent[Key] eventPressKey, {hideLogs} 
createEvent[Key] eventReleaseKey, {hideLogs}
createEvent[string] eventUpdateLineEnter
createEvent[void] eventStartLineEnter
createEvent[void] eventStopLineEnter
createEvent[string] eventSetLineEnter
createEvent[Rune] eventPressChar, {hideLogs}

var
  lineInput = false
  lineInputNew = false
  lineText: Atomic[ptr ref string]

when not defined(ginGLFM):
  var keyMods*: set[ModifierKey]
  
  proc keyCb*(win: Window, key: Key, scanCode: int32, action: KeyAction,
      mods: set[ModifierKey]) =
    keyMods = mods
    if lineInput:
      var pvalue = lineText.load
      var value = new(ref string)

      if pvalue != nil:
        value[] = pvalue[][]
        GC_unref(pvalue[])

      if action != kaUp and key == keyBackspace and value[] != "":
        value[] = value[0..^2]
        eventUpdateLineEnter.send(value[])

      GC_ref(value)
      lineText.store(addr value)
    case action:
    of kaDown:
      eventPressKey.send(key)
    of kaUp:
      eventReleaseKey.send(key)
    else:
      discard
  
  proc charCb*(win: Window, r: Rune) =
    eventPressChar.send(r)

    if not lineInput: return

    var pvalue = lineText.load
    var value = new(ref string)

    if pvalue != nil:
      value[] = pvalue[][]
      GC_unref(pvalue[])

    value[] &= $r

    eventUpdateLineEnter.send(value[])

    GC_ref(value)
    lineText.store(addr value)

proc setLineText*(data: string): bool {.gcsafe.} =
  let
    pvalue = lineText.load
    value = new(ref string)

  if pvalue != nil:
    value[] = pvalue[][]
    GC_unref(pvalue[])
  
  value[] = data

  GC_ref(value)
  lineText.store(addr value)
