import hangover/ui/elements/uielement
import hangover/ui/elements/uibutton
import hangover/ui/elements/uislider
import hangover/ui/elements/uipanel
import hangover/ui/elements/uigroup
import hangover/ui/elements/uidynamic
import hangover/ui/elements/uiimage
import hangover/ui/elements/uiinput
import hangover/ui/elements/uiscroll
import hangover/ui/elements/uitext
import hangover/ui/types/uirectangle
import hangover/ui/types/uitween
import hangover/ui/types/uibobber
import hangover/core/events
import hangover/core/graphics
import hangover/core/types/rect
import hangover/core/types/point
import hangover/core/types/vector2
import hangover/core/types/texture
import hangover/core/logging
import hangover/core/types/color
import algorithm
import macros
import sugar
import opengl
import math
import options

export uitext
export uiinput
export uipanel
export uigroup
export uiimage
export uislider
export uibutton
export uielement
export uirectangle
export uidynamic
export uiscroll
export uitween
export uibobber

type
  UIManager* {.acyclic.} = object
    ## a ui manager, stores ui elements
    elements*: seq[UIElement]
    size*: Vector2
    mousePos: Vector2
    scale*: float32

    fbo*: GLuint
    aSize: Vector2
    renderTexture: GLuint
    depthTexture: GLuint

var
  um*: UIManager
  ## The ui manager
  dragProc*: proc(done: bool)
  uiTransparency*: float32
  uiWidthTarget*: float32

proc uiWidth*(): float32 =
  return clamp(um.size.x, 2500, 3000)

proc uiHeight*(): float32 =
  let
    uiAspect = um.size.y / um.size.x
    uiscaledWidth = uiWidth() / um.scale
  return uiAspect * uiScaledWidth

#proc uiHeight*(): float32 =
#  result = um.size.y
#
#  if result < TARG_HEIGHT / 3:
#    return TARG_HEIGHT
#
#  if result > TARG_HEIGHT:
#    result /= floor(result / TARG_HEIGHT)
#  else:
#    result *= ceil(TARG_HEIGHT / result)
#
#  if result > TARG_HEIGHT / 2 * 3:
#    result -= TARG_HEIGHT / 2

proc mouseMove(data: pointer): bool =
  ## processes a mouse move event

  # get the event data
  var pos = cast[ptr tuple[x, y: float64]](data)[]

  let
    uiAspect = um.size.y / um.size.x
    uiscaledWidth = uiWidth() / um.scale
    uiSize = newPoint(uiScaledWidth.int, (uiAspect * uiScaledWidth).int)

  pos.x /= um.size.x / uiSize.x.float32
  pos.y /= um.size.y / uiSize.y.float32

  # update the ui mouse position
  um.mousePos = newVector2(pos.x, pos.y)

  # run check hover to update ui elements
  for e in um.elements:
    e.checkHover(newRect(newVector2(0, 0), um.asize), um.mousePos)

  # if the mouse is draging something update it
  if dragProc != nil:
    dragProc(false)

proc mouseClick(data: pointer): bool =
  ## processes a click event

  # get the event data
  let btn = cast[ptr int](data)[]

  # stop input if its active
  sendEvent(EVENT_STOP_LINE_ENTER, nil)

  # update drag
  for ei in 0..<len um.elements:
    let e = um.elements[ei]
    if e.focused:
      e.click(btn)
      capture e:
        dragProc = (done: bool) => e.drag(btn, done)

proc mouseRel(data: pointer): bool =
  # update drag to nothing
  if dragProc != nil:
    dragProc(true)
  dragProc = nil

proc mouseScroll(data: pointer): bool =
  let offset = cast[ptr Vector2](data)[]

  for ei in 0..<len um.elements:
    let e = um.elements[ei]
    e.scroll(offset)

proc resizeUI(data: pointer): bool =
  ## resizes the ui to the screen size

  # get the event data
  let size = cast[ptr tuple[x, y: int32]](data)[]
  if size.x != 0 and size.y != 0:
    um.size = newVector2(size.x.float32, size.y.float32)

proc initUIManager*(size: Point) =
  ## creates a new UIManager

  # set the size
  um.size = newVector2(size.x.float32, size.y.float32)
  um.scale = 1.0

  # attach events
  createListener(EVENT_MOUSE_MOVE, mouseMove)
  createListener(EVENT_MOUSE_CLICK, mouseClick)
  createListener(EVENT_MOUSE_RELEASE, mouseRel)
  createListener(EVENT_MOUSE_SCROLL, mouseScroll)
  createListener(EVENT_RESIZE, resizeUI)

  glGenFramebuffers(1, addr um.fbo)
  glGenRenderbuffers(1, addr um.depthTexture);
  glGenTextures(1, addr um.renderTexture);

proc addUIElement*(e: UIElement) =
  ## adds a single ui element to the ui
  um.elements.add(e)

proc addUIElements*(elems: seq[UIElement]) =
  ## adds ui elements to the ui
  um.elements.add(elems)

proc drawUI*() =
  ## draws the ui
  let
    uiAspect = um.size.y / um.size.x
    uiscaledWidth = uiWidth() / um.scale
    uiSize = newPoint(uiScaledWidth.int, (uiAspect * uiScaledWidth).int)

  if uiSize != um.aSize.toPoint() and uiSize.toVector2().distanceSq(newVector2(0, 0)) > 128 * 128:
    try:
      glBindFramebuffer(GL_FRAMEBUFFER, um.fbo)
      glBindTexture(GL_TEXTURE_2D, um.renderTexture)
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, uiSize.x.GLsizei,
                   uiSize.y.GLsizei, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
      glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, um.renderTexture, 0)

      glBindRenderbuffer(GL_RENDERBUFFER, um.depthTexture);
      # glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, uiSize.x.GLsizei,
      #                        uiSize.y.GLsizei)
      #glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
      #                           GL_RENDERBUFFER, um.depthTexture)

      if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
        LOG_ERROR "ho->ui", "failed to create ui fb"
        return

      glBindFramebuffer(GL_FRAMEBUFFER, 0)
      um.aSize = uiSize.toVector2()
    except Exception as ex:
      LOG_ERROR $ex[]

  ## draw the ui
  finishDraw()
  glBindFramebuffer(GL_FRAMEBUFFER, um.fbo)
  setCameraSize(um.aSize.x.int32, um.aSize.y.int32)

  glClearColor(0, 0, 0, 0)
  glClear(GL_COLOR_BUFFER_BIT)

  var postpone: Option[UIElement]

  for e in um.elements:
    if e.focused:
      postpone = some(e)
    else:
      e.draw(newRect(newVector2(0, 0), um.aSize))
  if postpone.is_some():
    postpone.get().draw(newRect(newVector2(0, 0), um.aSize))

  finishDraw()
  glBindFramebuffer(GL_FRAMEBUFFER, 0)

  setCameraSize(um.size.x.int32, um.size.y.int32)

  let tex = Texture(tex: um.renderTexture)
  tex.draw(newRect(0, 0, 1, 1), newRect(0, 0, um.size.x, um.size.y), flip = [
      false, true], color = newColor(255, 255, 255, (255 * uiTransparency).uint8))

proc updateUI*(dt: float32) =
  ## processes a ui tick
  for i in 0..<len um.elements:
    um.elements[i].update(newRect(newVector2(0, 0), um.asize),
        um.mousePos, dt)
  for t in tweens:
    t.update(dt)
  for b in bobbers:
    b.update(dt, um.mousePos)

proc setUIActive*(i: int, value: bool) =
  ## sets the ui element at index i to active
  if um.elements[i].isActive != value:
    um.elements[i].active = value
    for e in um.elements:
      e.checkHover(newRect(newVector2(0, 0), um.asize), um.mousePos)
    for t in tweens:
      t.reset()

proc uiNavigate*(dir: UIDir) =
  defer:
    for e in um.elements:
      if not e.isActive: continue
      if e.focused:
        um.mousePos = e.center(newRect(newVector2(0, 0), um.asize))
        return

  let bounds = newRect(newVector2(0, 0), um.asize)
  case dir:
    of UIScrollUp:
      let offset = newVector2(0, -10)

      for ei in 0..<len um.elements:
        let e = um.elements[ei]
        e.scroll(offset)
    of UIScrollDown:
      let offset = newVector2(0, 10)

      for ei in 0..<len um.elements:
        let e = um.elements[ei]
        e.scroll(offset)
    of UISelect:
      for e in um.elements:
        if not e.isActive: continue

        if e.focused:
          e.click(1)
          return
    of UINext, UIDown, UIRight:
      var focusNext = false

      for e in um.elements:
        if not e.isActive: continue

        if focusNext:
          if e.focusable():
            e.focus(true)
            return
        if e.navigate(dir, bounds):
          if e.focused:
            return
          focusNext = true

      for e in um.elements:
        if not e.isActive: continue

        if e.focusable():
          e.focus(true)
          return

    of UIPrev, UIUp, UILeft:
      var focusNext = false

      for e in um.elements.reversed():
        if not e.isActive: continue

        if focusNext:
          if e.focusable():
            e.focus(true)
            return
        if e.navigate(dir, bounds):
          if e.focused:
            return
          focusNext = true

      for e in um.elements.reversed():
        if not e.isActive: continue

        if e.focusable():
          e.focus(true)
          return
    else:
      discard


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
