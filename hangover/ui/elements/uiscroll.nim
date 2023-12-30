import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/logging
import hangover/ui/elements/uielement
import hangover/ui/elements/uigroup
import hangover/ui/types/uisprite
import options
import algorithm
import sugar

type
  UIScroll* = ref object of UIGroup
    vpHeight: float32
    tmpVal: float32
    scrollClick: bool

    smooth*: float32

    height*: float32
    scrollPos*: Vector2
    scrollVis*: Vector2
    sprite*, handleSprite*: UISprite
    scrollSensitivity*: float
    onScroll*: (Vector2) -> void
    scrollFocus: bool

method draw*(s: UIScroll, parentRect: Rect) =
  if not s.isActive:
    return

  let
    vp = s.bounds.toRect(parentRect)
    oldScissor = textureScissor
  var
    bounds = s.bounds.toRect(parentRect)

  s.vpHeight = vp.height * uiScaleMult

  if s.height > s.vpHeight:
    let
      value = s.scrollVis.y / (s.height - s.vpHeight)
      posy: float32 = ((bounds.y + 50) * (1 - value)) + (bounds.y + bounds.height - 50) * (value) - 50
      posx: float32 = bounds.x + bounds.width - 25
    s.sprite.draw(newRect(posx - 25, bounds.y, 50, bounds.height))
    s.handleSprite.draw(newRect(bounds.x + bounds.width - 50, posy, 50, 100))
    bounds.width -= 50

  bounds.y = bounds.y - s.scrollVis.y
  bounds.x = bounds.x - s.scrollVis.x

  textureScissor = vp.scale(uiScaleMult)

  var postpone: Option[UIElement]

  for i in 0..<s.elements.len:
    if s.elements[i].focused:
      postpone = some(s.elements[i])
    else:
      s.elements[i].draw(bounds)

  if postpone.is_some():
    postpone.get().draw(bounds)

  textureScissor = oldScissor

method navigate*(s: UIScroll, dir: UIDir, parent: Rect): bool =
  if not s.focused:
    return false

  let bounds = s.bounds.toRect(parent)

  case dir:
    of UISelect:
      return false
    of UINext, UIDown, UIRight:
      var focusNext = false

      for e in s.elements:
        if not e.isActive: continue

        if focusNext:
          if e.focusable():
            s.scrollPos.y = (e.bounds.toRect(newRect(0, 0, 0, s.vpHeight)).y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0))
            if s.onScroll != nil:
              s.onScroll(s.scrollPos)
            e.focus(true)
            return true

        if e.navigate(dir, bounds):
          if e.focused:
            return true
          focusNext = true

      if focusNext: s.focus(false)
      return true
    of UIPrev, UIUp, UILeft:
      var focusNext = false

      for e in s.elements.reversed():
        if not e.isActive: continue

        if focusNext:
          if e.focusable():
            s.scrollPos.y = (e.bounds.toRect(newRect(0, 0, 0, s.vpHeight)).y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0))
            if s.onScroll != nil:
              s.onScroll(s.scrollPos)
            e.focus(true)
            return true

        if e.navigate(dir, bounds):
          if e.focused: return true
          focusNext = true

      if focusNext: s.focus(false)
      return true
    else: discard

method checkHover*(s: UIScroll, parentRect: Rect, mousePos: Vector2) =
  s.focused = false
  
  var bounds = s.bounds.toRect(parentRect)

  s.tmpVal = (1 - ((bounds.y - 15 + bounds.height -
      mousePos.y) / (bounds.height - 30)).clamp(0, 1)) * max(s.height - s.vpHeight, 0) 
  s.scrollFocus = mousePos.x > bounds.x + bounds.width - 50 and mousePos.x < bounds.x + bounds.width

  if not s.isActive:
    return
  if s.isDisabled != nil and s.isDisabled():
    return

  if s.scrollFocus:
    s.focused = true

  bounds.width -= 50
  bounds.y = bounds.y - s.scrollVis.y
  bounds.x = bounds.x - s.scrollVis.x

  for i in 0..<s.elements.len:
    s.elements[i].checkHover(bounds, mousePos)
    if s.elements[i].focused:
      s.focused = true

method click*(s: UIScroll, button: int) =
  s.scrollClick = s.scrollFocus
  if s.scrollFocus:
    s.scrollPos.y = s.tmpVal
    if s.onScroll != nil:
      s.onScroll(s.scrollPos)
    return

  for i in 0..<s.elements.len:
    if s.elements[i].focused:
      s.elements[i].click(button)
      capture i:
        s.dragProc = proc(done: bool) = s.elements[i].drag(button, done)

method scroll*(s: UIScroll, offset: Vector2) =
  if not s.isActive:
    return
  s.scrollPos.y = (s.scrollPos.y + s.scrollSensitivity * offset.y).clamp(0, max(s.height - s.vpHeight, 0))
  if s.onScroll != nil:
    s.onScroll(s.scrollPos)

method drag*(s: UIScroll, button: int, done: bool) =
  if s.scrollClick:
    s.scrollPos.y = s.tmpVal
    if s.onScroll != nil:
      s.onScroll(s.scrollPos)
  elif s.dragProc != nil:
    s.dragProc(done)

method focus*(s: UIScroll, focus: bool) =
  ## returns true if you can focus the element
  s.focused = focus
  for e in s.elements:
    if not e.isActive: continue

    if e.focusable():
      e.focus(focus)
      if focus:
        s.scrollPos.y = (e.bounds.toRect(newRect(0, 0, 0, s.vpHeight)).y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0))
        if s.onScroll != nil:
          s.onScroll(s.scrollPos)
        return

method center*(s: UIScroll, parent: Rect): Vector2 =
  var bounds = s.bounds.toRect(parent)

  bounds.width -= 50
  bounds.y = bounds.y - s.scrollPos.y
  bounds.x = bounds.x - s.scrollPos.x

  ## returns true if you can focus the element
  for e in s.elements:
    if not e.isActive: continue

    if e.focused:
      return e.center(bounds)

method update*(s: UIScroll, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  if not s.isActive:
    return
  s.scrollVis = lerp(s.scrollVis, s.scrollPos, clamp(dt * s.smooth, 0, 1))

  let bounds = s.bounds.toRect(parentRect)
  for i in 0..<s.elements.len:
    s.elements[i].update(bounds, mousePos, dt)
