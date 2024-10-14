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
import hangover/ui/elements/uitabs
import hangover/ui/types/uirectangle
import hangover/ui/types/uitween
import hangover/ui/types/uibobber
import hangover/ui/types/uilayout
import hangover/ui/types/uitooltip
import hangover/ui/types/uifield
import hangover/core/events
import hangover/core/graphics
import hangover/core/types/rect
import hangover/core/types/point
import hangover/core/types/vector2
import hangover/core/types/texture
import hangover/core/types/color
import hangover/core/audio
import hangover/core/logging
import hangover/core/loop
import hangover/rendering/shapes
import algorithm
import macros
import sugar
import opengl
import math
import options
import delaunay
import sequtils
import tables
import hashes
import strformat

export uitext
export uiinput
export uipanel
export uigroup
export uiimage
export uislider
export uibutton
export uielement
export uirectangle
export uilayout
export uitabs
export uitooltip
export uidynamic
export uiscroll
export uitween
export uibobber
export uifield

type
  UIBorder* = enum
    borderTop
    borderBottom
    borderLeft
    borderRight

  UIManager* {.acyclic.} = object
    ## a ui manager, stores ui elements
    elements*: seq[UIElement]
    size*: Vector2
    mousePos: Vector2
    scale*: float32
    aspect*: float32

    fbo*: GLuint
    aSize: Vector2
    renderTexture: GLuint
    depthTexture: GLuint

    border*: array[UIBorder, int]

var
  um*: UIManager
  ## The ui manager
  dragProc*: proc(done: bool)
  uiTransparency*: float32
  uiWidthTarget*: float32

proc uiWidth*(): float32 =
  let base = um.size.x - um.border[borderLeft].float32 - um.border[borderRight].float32
  return clamp(base, 2500, 3000)

proc uiHeight*(): float32 =
  let
    uiscaledWidth = uiWidth() / um.scale
  return um.aspect * uiScaledWidth

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

proc mouseMove(data: pointer): bool {.cdecl.} =
  ## processes a mouse move event

  # get the event data
  var pos = cast[ptr tuple[x, y: float64]](data)[]

  let
    uiscaledWidth = uiWidth() / um.scale
    uiSize = newPoint(uiScaledWidth.int, (um.aspect * uiScaledWidth).int)

  pos.x -= um.border[borderLeft].float32
  pos.y -= um.border[borderTop].float32

  pos.x /= (um.size.x - um.border[borderLeft].float32 - um.border[borderRight].float32) / uiSize.x.float32
  pos.y /= (um.size.y - um.border[borderTop].float32 - um.border[borderBottom].float32) / uiSize.y.float32

  # update the ui mouse position
  um.mousePos = newVector2(pos.x, pos.y)

  # run check hover to update ui elements
  for e in um.elements:
    e.checkHover(newRect(newVector2(0, 0), um.asize), um.mousePos)

  # if the mouse is draging something update it
  if dragProc != nil:
    dragProc(false)

proc mouseClick(data: pointer): bool {.cdecl.} =
  ## processes a click event

  # get the event data
  let btn = cast[ptr int](data)[]

  # stop input if its active
  sendEvent(EVENT_STOP_LINE_ENTER, nil)

  # update drag
  for ei in 0..<len um.elements:
    let e = um.elements[ei]
    e.click(btn, false)
    if e.propagate():
      capture e:
        dragProc = (done: bool) => e.drag(btn, done)

proc propagateUI*() = 
  for e in um.elements:
    if not e.isActive: continue
    discard e.propagate()

proc mouseRel(data: pointer): bool {.cdecl.} =
  # update drag to nothing
  if dragProc != nil:
    dragProc(true)
  dragProc = nil

proc mouseScroll(data: pointer): bool {.cdecl.} =
  let offset = cast[ptr Vector2](data)[]

  for ei in 0..<len um.elements:
    let e = um.elements[ei]
    e.scroll(offset)

    e.checkHover(newRect(newVector2(0, 0), um.asize), um.mousePos)

proc resizeUI(data: pointer): bool {.cdecl.} =
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

  withGraphics:
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
    unscaledSize = newVector2(
      um.size.x - um.border[borderLeft].float32 - um.border[borderRight].float32,
      um.size.y - um.border[borderTop].float32 - um.border[borderBottom].float32,
    )

  um.aspect = unscaledSize.y / unscaledSize.x

  let
    uiscaledWidth = uiWidth() / um.scale
    uiSize = newPoint(uiScaledWidth.int, (um.aspect * uiScaledWidth).int)

  if uiSize != um.aSize.toPoint() and uiSize.toVector2().distanceSq(newVector2(
      0, 0)) > 128 * 128:
    withGraphics:
      try:
        glBindFramebuffer(GL_FRAMEBUFFER, um.fbo)
        glBindTexture(GL_TEXTURE_2D, um.renderTexture)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, uiSize.x.GLsizei,
                  uiSize.y.GLsizei, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_TEXTURE_2D, um.renderTexture, 0)

        glBindRenderbuffer(GL_RENDERBUFFER, um.depthTexture);
        # glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, uiSize.x.GLsizei,
        #                        uiSize.y.GLsizei)
        # glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
        #                           GL_RENDERBUFFER, um.depthTexture)

        if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
          LOG_ERROR "ho->ui", "failed to create ui fb"
          return

        um.aSize = uiSize.toVector2()
      
        LOG_INFO "ho->ui", "resize UI to ", &"{um.aSize.x}x{um.aSize.y}"
      except Exception as ex:
        LOG_ERROR $ex[]
      finally:
        glBindFramebuffer(GL_FRAMEBUFFER, 0)

  ## draw the ui
  finishDraw()

  withGraphics:
    glBindFramebuffer(GL_FRAMEBUFFER, um.fbo)
  setCameraSize(um.aSize.x.int32, um.aSize.y.int32)

  withGraphics:
    glClearColor(0, 0, 0, 0)
    glClear(GL_COLOR_BUFFER_BIT)

  var postpone: Option[UIElement]
  
  rectUpdate = true

  for e in um.elements:
    if e.focused:
      postpone = some(e)
    else:
      e.draw(newRect(newVector2(0, 0), um.aSize))
  if postpone.is_some():
    postpone.get().draw(newRect(newVector2(0, 0), um.aSize))

  rectUpdate = false

  if uiDebug:
    var tmp: seq[UIElement] = @[]

    for e in um.elements:
      e.drawDebug(newRect(newVector2(0, 0), um.aSize))
      for e in um.elements:
        if e.isActive:
          tmp &= e.getElems()

    for e in tmp:
      drawCircleOutline(e.navCenter, 20, 3, COLOR_RED)
      for f in e.focusDir:
        if f != nil:
          if not f.focused:
            drawLine(e.navCenter, f.navCenter, 5, COLOR_RED)

  for e in um.elements:
    e.drawTooltip(um.mousePos, um.aSize.toPoint())

  if uiDebug:      
    drawCircleOutline(um.mousePos, 10, 5, COLOR_CYAN)

  finishDraw()

  withGraphics:
    glBindFramebuffer(GL_FRAMEBUFFER, 0)

  setCameraSize(um.size.x.int32, um.size.y.int32)

  let tex = Texture(tex: um.renderTexture)
  tex.draw(
    newRect(0, 0, 1, 1),
    newRect(um.border[borderLeft], um.border[borderTop], unscaledSize.x, unscaledSize.y),
    flip = [false, true],
    color = newColor(255, 255, 255, (255 * uiTransparency).uint8),
    contrast = ContrastEntry(mode: noContrast),
  )

proc isUITooltip*(): bool =
  for e in um.elements:
    if e.isTooltip():
      return true

proc updateUI*(dt: float32) =
  ## processes a ui tick
  for i in 0..<len um.elements:
    um.elements[i].updateTooltip(dt)
    um.elements[i].update(
      newRect(newVector2(0, 0), um.asize),
      um.mousePos,
      dt,
      true,
    )
    um.elements[i].updateCenter(newRect(newVector2(0, 0), um.asize))
  for t in tweens:
    t.update(dt)
  bobberScreen = um.asize
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

var
  navHash: Hash

proc uiNavigate*(dir: UIDir): bool =
  try:
    let bounds = newRect(newVector2(0, 0), um.asize)
    case dir:
    of UIScrollUp:
      let offset = newVector2(0, -10)

      var focused = false

      for ei in 0..<len um.elements:
        let e = um.elements[ei]
        if e.focused:
          focused = true   

        e.scroll(offset)

      return true
    of UIScrollDown:
      let offset = newVector2(0, 10)
      
      var focused = false

      for ei in 0..<len um.elements:
        let e = um.elements[ei]
        if e.focused:
          focused = true 
 

      return true
    of UISelect:
      for e in um.elements:
        e.click(1, true)

        let tmp = false
        result = result or tmp
    of UIUp, UIDown, UILeft, UIRight:
      var tmp: seq[UIElement] = @[]

      for e in um.elements:
        if e.isActive:
          tmp &= e.getElems()

      if tmp.len == 0:
        return

      for t in tmp:
        if t.focused:
          if t.navigate(dir, bounds):
            return true
          break

      var tmpa: array[UIUp..UIRight, float32]
      tmpa[UIUp] = Inf.float32
      tmpa[UIDown] = Inf.float32
      tmpa[UILeft] = Inf.float32
      tmpa[UIRight] = Inf.float32

      let old = navHash

      navHash = 0
      for e in tmp:
        navHash = navHash !& e.hash()
      navHash = !$navHash

      if old != navHash:
        var points: seq[Vector2]
        var dists: Table[int, array[UIUp..UIRight, float32]]
        var idx = 0
        for e in tmp:
          points &= e.navPoint
          dists[idx] = tmpa
          idx += 1

        for e in tmp:
          e.focusDir[UIUp] = nil
          e.focusDir[UIDown] = nil
          e.focusDir[UILeft] = nil
          e.focusDir[UIRight] = nil

        for edge in triangulate(points.mapIt((x: it.x.float, y: it.y.float, v: points.find(it)))):
          let
            a = tmp[edge.a.v]
            b = tmp[edge.b.v]

            xd: float32 = abs(edge.a.x - edge.b.x) * 5 # newVector2(edge.a.x, edge.a.y).distance(newVector2(edge.b.x, edge.b.y))
            yd: float32 = abs(edge.a.y - edge.b.y) * 5

          if edge.a.x < edge.b.x:
            let dist = edge.b.x - edge.a.x + yd
            if dists[edge.a.v][UIRight] > dist:
              dists[edge.a.v][UIRight] = dist
              a.focusDir[UIRight] = b
          if edge.a.x > edge.b.x:
            let dist = edge.a.x - edge.b.x + yd
            if dists[edge.a.v][UILeft] > dist:
              dists[edge.a.v][UILeft] = dist
              a.focusDir[UILeft] = b
          if edge.a.y < edge.b.y:
            let dist = edge.b.y - edge.a.y + xd
            if dists[edge.a.v][UIDown] > dist:
              dists[edge.a.v][UIDown] = dist
              a.focusDir[UIDown] = b
          if edge.a.y > edge.b.y:
            let dist = edge.a.y - edge.b.y + xd
            if dists[edge.a.v][UIUp] > dist:
              dists[edge.a.v][UIUp] = dist
              a.focusDir[UIUp] = b
          if edge.b.x < edge.a.x:
            let dist = edge.a.x - edge.b.x + yd
            if dists[edge.b.v][UIRight] > dist:
              dists[edge.b.v][UIRight] = dist
              b.focusDir[UIRight] = a
          if edge.b.x > edge.a.x:
            let dist = edge.b.x - edge.a.x + yd
            if dists[edge.b.v][UILeft] > dist:
              dists[edge.b.v][UILeft] = dist
              b.focusDir[UILeft] = a
          if edge.b.y < edge.a.y:
            let dist = edge.a.y - edge.b.y + xd
            if dists[edge.b.v][UIDown] > dist:
              dists[edge.b.v][UIDown] = dist
              b.focusDir[UIDown] = a
          if edge.b.y > edge.a.y:
            let dist = edge.b.y - edge.a.y + xd
            if dists[edge.b.v][UIUp] > dist:
              dists[edge.b.v][UIUp] = dist
              b.focusDir[UIUp] = a

      for t in tmp:
        if t.focused:
          if t.focusDir[dir] != nil:
            t.focus(false)
            t.focusDir[dir].focus(true)
              
            for e in um.elements:
              if not e.isActive: continue
              discard e.propagate()

            um.mousePos = t.focusDir[dir].bounds.lastCenter
            result = true
            buttonHoverSound.play()
          return result

      for e in um.elements:
        if not e.isActive: continue
        discard e.propagate()

      tmp[0].focus(true)
    of UIPrev, UINext:
      for e in um.elements:
        var tmp = e.navigate(dir, bounds)
        result = result or tmp
      for e in um.elements:
        if not e.isActive: continue
        discard e.propagate()
    else:
      discard
  except AssertionError:
    LOG_TRACE "ho->ui", "triangle fail"
    navHash = 0

proc isDashNode(n: NimNode): bool =
  n.kind == nnkPrefix and $n[0] == "-"

proc uiAux(outName, body: NimNode): NimNode =
  var nodes: seq[NimNode]
  var tmpName = "tmp" & $outName
  result = newNimNode(nnkStmtList)
  for c in body:
    if c.isDashNode():
      nodes &= c
    else:
      assert false, "Invalid ast"
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
        var outName = ident(tmpName & "Sub" & $i)
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
