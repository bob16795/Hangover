import hangover/ui/elements/uielement
import hangover/ui/elements/uibutton
import hangover/ui/elements/uislider
import hangover/ui/elements/uipanel
import hangover/ui/elements/uigroup
import hangover/ui/elements/uiimage
import hangover/ui/elements/uiinput
import hangover/ui/elements/uitext
import hangover/ui/types/uirectangle
import hangover/core/events
import hangover/core/graphics
import hangover/core/types/rect
import hangover/core/types/point
import hangover/core/types/vector2
import hangover/core/types/texture
import macros
import sugar

export uitext
export uiinput
export uipanel
export uigroup
export uiimage
export uislider
export uibutton
export uielement
export uirectangle

type
  UIManager* {.acyclic.} = object
    ## a ui manager, stores ui elements
    elements: seq[UIElement]
    size: Vector2
    mousePos: Vector2

var
  um*: UIManager
  ## The ui manager
  drag: UIElement
  uiScaleMult*: float32 = 1
  ## scales the ui, ammount of pixels in 1 ui pixel
  last: int

proc mouseMove(data: pointer): bool =
  ## processes a mouse move event
  
  # get the event data
  var pos = cast[ptr tuple[x, y: float64]](data)[]
  
  # update the ui mouse position
  um.mousePos = newVector2(pos.x, pos.y) / uiScaleMult

  # run check hover to update ui elements
  for e in um.elements:
    e.checkHover(newRect(newVector2(0, 0), um.size / uiScaleMult), um.mousePos)
  
  # if the mouse is draging something update it
  if drag != nil:
    drag.drag(last)

proc mouseClick(data: pointer): bool =
  ## processes a click event
  
  # get the event data
  var btn = cast[ptr int](data)[]
  last = btn

  # stop input if its active
  sendEvent(EVENT_STOP_LINE_ENTER, nil)

  # update drag
  for e in um.elements:
    if e.focused:
      e.click(btn)
      drag = e

proc mouseRel(data: pointer): bool =
  # update drag to nothing
  drag = nil

proc resizeUI(data: pointer): bool =
  ## resizes the ui to the screen size
 
  # get the event data
  var size = cast[ptr tuple[x, y: int32]](data)[]
  um.size = newVector2(size.x.float32, size.y.float32)

proc initUIManager*(size: Point) =
  ## creates a new UIManager
  
  # set the size
  um.size = newVector2(size.x.float32, size.y.float32)

  # attach events
  createListener(EVENT_MOUSE_MOVE, mouseMove)
  createListener(EVENT_MOUSE_CLICK, mouseClick)
  createListener(EVENT_MOUSE_RELEASE, mouseRel)
  createListener(EVENT_RESIZE, resizeUI)

proc addUIElement*(e: UIElement) =
  ## adds a single ui element to the ui
  um.elements.add(e)

proc addUIElements*(elems: seq[UIElement]) =
  ## adds ui elements to the ui
  um.elements.add(elems)

proc drawUI*() =
  ## draws the ui
  
  # scale the ui if needed
  if uiScaleMult != 1:
    finishDraw()
    scaleBuffer(uiScaleMult)
    uiSpriteScaleMult = 1 / uiScaleMult
    uiElemScale = uiScaleMult
  

  # draw the ui
  for e in um.elements:
    e.draw(newRect(newVector2(0, 0), um.size / uiScaleMult))

  # reset scale
  if uiScaleMult != 1:
    finishDraw()
    scaleBuffer(1)
    uiSpriteScaleMult = 1
    uiElemScale = 1

proc updateUI*(dt: float32) =
  ## processes a ui tick
  for i in 0..<len um.elements:
    um.elements[i].update(newRect(newVector2(0, 0), um.size / uiScaleMult),
        um.mousePos, dt)

proc setUIActive*(i: int, value: bool) =
  ## sets the ui element at index i to active
  um.elements[i].isActive = value

proc isDashNode(n: NimNode): bool =
  n.kind == nnkPrefix and $n[0] == "-"

proc uiAux(outName, body: NimNode): NimNode =
  var nodes: seq[NimNode]
  var tmpName = "tmp" & $outName
  result = newNimNode(nnkStmtList)
  for c in body:
    if c.isDashNode():
      nodes &= c
  result &= newNimNode(nnkVarSection).add(
    newIdentDefs(ident(tmpName), ident("UIElement")),
    newIdentDefs(outName, newNimNode(nnkBracketExpr).add(ident(
        "seq"), ident("UIElement")))
  )
  var i = 0
  for n in nodes:
    var name = $n[1]
    result &= newAssignment(ident(tmpName), newCall(ident(name)))
    result &= newAssignment(newDotExpr(ident(tmpName), ident("isActive")),
        ident("true"))
    for a in n[2]:
      case a.kind:
      of nnkAsgn:
        var assignName = newDotExpr(newDotExpr(ident(tmpName), ident(name)),
            ident($a[0]))
        var assignValue = a[1]
        result &= newAssignment(assignName, assignValue)
      of nnkCall:
        var outName = ident(tmpName & "_Sub" & $i)
        i += 1
        var assignName = newDotExpr(newDotExpr(ident(tmpName), ident(name)),
            ident($a[0]))
        result &= uiAux(outName, a[1])
        result &= newAssignment(assignName, outName)
      else:
        assert false, "Invalid ast"

    result &= newCall(newDotExpr(outName, ident("add")), ident(tmpName))

macro createUIElems*(name: untyped, body: untyped): untyped =
  ## creates a ui system stores the result into a seq[UIElement] in name
  uiAux(name, body)

