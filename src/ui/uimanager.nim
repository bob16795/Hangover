import ui/elements/uielement
import ui/elements/uibutton
import ui/elements/uislider
import ui/elements/uipanel
import ui/elements/uigroup
import ui/elements/uiimage
import ui/elements/uiinput
import ui/elements/uitext
import ui/types/uirectangle
import core/events
import core/types/rect
import core/types/point
import core/types/vector2
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
    elements: seq[UIElement]
    size: Vector2
    mousePos: Vector2

var
  um*: UIManager
  drag*: UIElement
  last: int

proc mouseMove*(data: pointer) =
  var pos = cast[ptr tuple[x, y: float64]](data)[]
  um.mousePos = newVector2(pos.x, pos.y)
  for e in um.elements:
    discard e.checkHover(newRect(newVector2(0, 0), um.size), um.mousePos)
  if drag != nil:
    drag.drag(last)

proc mouseClick*(data: pointer) =
  var btn = cast[ptr int](data)[]
  last = btn
  sendEvent(EVENT_STOP_LINE_ENTER, nil)
  for e in um.elements:
    if e.focused:
      e.click(btn)
      drag = e

proc mouseRel(data: pointer) =
  drag = nil

proc resizeUI*(data: pointer) =
  var size = cast[ptr tuple[x, y: int32]](data)[]
  um.size = newVector2(size.x.float32, size.y.float32)

proc initUIManager*(size: Point) =
  um.size = newVector2(size.x.float32, size.y.float32)
  createListener(EVENT_MOUSE_MOVE, mouseMove)
  createListener(EVENT_MOUSE_CLICK, mouseClick)
  createListener(EVENT_MOUSE_RELEASE, mouseRel)
  createListener(EVENT_RESIZE, resizeUI)

proc addUIElement*(e: UIElement) =
  um.elements.add(e)

proc addUIElements*(elems: seq[UIElement]) =
  um.elements.add(elems)

proc drawUI*() =
  for e in um.elements:
    e.draw(newRect(newVector2(0, 0), um.size))

proc updateUI*(dt: float32) =
  for i in 0..<len um.elements:
    discard um.elements[i].update(newRect(newVector2(0, 0), um.size),
        um.mousePos, dt)

proc setUIActive*(i: int, value: bool) =
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
  uiAux(name, body)

when isMainModule:
  expandMacros:
    createUIElems root:
      - UIGroup:
        bounds = newUIRectangle(0, 0, 0, 0, 0, 0, 1, 1)
        elements:
          - UIPanel:
            bounds = newUIRectangle(0, 0, 0, 0, 0, 0, 1, 1)
        tmpElements:
          - UIPanel:
            bounds = newUIRectangle(0, 0, 0, 0, 0, 0, 1, 1)

          - UIText:
            bounds = newUIRectangle(0, 0, 0, 0, 0, 0, 1, 1)

            update = ()=>"Check Mate"
