import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/logging
import hangover/ui/elements/uielement
import hangover/ui/elements/uigroup
import hangover/ui/types/uisprite
import hangover/ui/types/uifield
import hangover/rendering/shapes
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
    scrollPos*: UIField[Vector2]
    scrollVis*: Vector2
    sprite*, handleSprite*: UISprite
    scrollSensitivity*: float
    onScroll*: (Vector2) -> void
    scrollFocus: bool
    inside: bool

method draw*(s: UIScroll, parentRect: Rect) =
  if not s.isActive:
    return

  var
    parent_rect_moved = parent_rect

  parent_rect_moved.x -= s.scrollVis.x
  parent_rect_moved.y -= s.scrollVis.y

  let
    oldScissor = textureScissor

  var
    vp = s.bounds.toRect(parent_rect)
    bounds = s.bounds.toRect(parent_rect_moved)
    scrollBounds = bounds

  s.vpHeight = vp.height * uiScaleMult

  if s.height > s.vpHeight:
    let
      value = s.scrollVis.y / (s.height - s.vpHeight)
      posy: float32 = ((vp.y + 80) * (1 - value)) + (vp.y + vp.height - 80) * value - 80
      posx: float32 = vp.x + vp.width - 80 * 0.5
    s.sprite.draw(newRect(posx - 80 * 0.5, vp.y, 80, vp.height), contrast = ContrastEntry(mode: fg))
    s.handleSprite.draw(newRect(vp.x + vp.width - 80, posy, 80, 160), contrast = ContrastEntry(mode: fg))
  
    # slider size
    bounds.width -= 80

  textureScissor = vp.scale(uiScaleMult)

  var postpone: seq[UIElement]

  for i in 0..<s.elements.len:
    if s.elements[i].focused:
      postpone &= s.elements[i]
    else:
      s.elements[i].draw(bounds)

  for p in postpone:
    p.draw(bounds)

  textureScissor = oldScissor

method navigate*(s: UIScroll, dir: UIDir, parent_rect: Rect): bool =
  var
    parent_rect_moved = parent_rect

  parent_rect_moved.x -= s.scrollVis.x
  parent_rect_moved.y -= s.scrollVis.y

  var bounds = s.bounds.toRect(parent_rect_moved)

  if s.height > s.vpHeight:
    bounds.width -= 80

  case dir:
  of UIPrev, UINext:
    for e in s.elements:
      let tmp = e.navigate(dir, bounds)
      result = result or tmp
  else: discard

method checkHover*(s: UIScroll, parent_rect: Rect, mousePos: Vector2) =
  s.focused = false
  s.inside = false
  if not s.isActive:
    return
  if s.disabled.value:
    return

  var
    parent_rect_moved = parent_rect

  parent_rect_moved.x -= s.scrollVis.x
  parent_rect_moved.y -= s.scrollVis.y

  var
    vp = s.bounds.toRect(parent_rect)
    bounds = s.bounds.toRect(parent_rect_moved)
    scroll_bounds = vp

  if s.height > s.vpHeight:
    scroll_bounds.x += scrollBounds.width - 80
    scroll_bounds.width = 80
    vp.width -= 80

    bounds.width -= 80
  else:
    scroll_bounds.x += scrollBounds.width
    scroll_bounds.width = 0

  s.tmpVal = ((mousePos.y - scroll_bounds.y) / scroll_bounds.height).clamp(0, 1)
  s.scrollFocus = mousePos in scroll_bounds

  s.inside = not s.scrollFocus and mousePos in vp

  if not s.inside: 
    return

  for i in 0..<s.elements.len:
    s.elements[i].checkHover(bounds, mousePos)
    if s.elements[i].focused and s.inside:
      s.focused = true

method click*(s: UIScroll, button: int, key: bool) =
  if not key and s.scrollFocus:
    s.scrollClick = true
    s.scrollPos.value = newVector2(
      s.scrollPos.value.x,
      s.tmpVal * max(0, s.height - s.vpHeight),
    )

    if s.onScroll != nil:
      s.onScroll(s.scrollPos.value)
    return

  if s.inside:
    for i in 0..<s.elements.len:
      s.elements[i].click(button, key)
      if not key and s.elements[i].propagate():
        capture i:
          s.dragProc = proc(done: bool) = s.elements[i].drag(button, done)

method scroll*(s: UIScroll, offset: Vector2) =
  if not s.isActive:
    return

  s.scrollPos.value = newVector2(
    s.scrollPos.value.x,
    s.scrollPos.value.y + s.scrollSensitivity * offset.y,
  )

  if s.onScroll != nil:
    s.onScroll(s.scrollPos.value)

method drag*(s: UIScroll, button: int, done: bool) =
  if s.scrollClick:
    s.scrollPos.value = newVector2(
      s.scrollPos.value.x,
      s.tmpVal * max(0, s.height - s.vpHeight),
    )
    if s.onScroll != nil:
      s.onScroll(s.scrollPos.value)
  elif s.dragProc != nil:
    s.dragProc(done)

  if done:
    s.scrollClick = false

method focus*(s: UIScroll, focus: bool) =
  ## returns true if you can focus the element
  s.focused = focus
  s.inside = focus
  for e in s.elements:
    if not e.isActive: continue

    if e.focusable():
      e.focus(focus)

      if focus:
        let
          min_y = e.bounds.YMin + e.bounds.anchorYMin * s.vpHeight
          max_y = e.bounds.YMax + e.bounds.anchorYMax * s.vpHeight

          y = (min_y + max_y) / 2
        
          diff = s.scrollPos.value.y -
            (y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0))
  
        for j in 0..<s.elements.len:
          s.elements[j].bounds.lastCenter.y += diff

        s.scrollPos.value = newVector2(
          s.scrollPos.value.x,
          (y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0)),
        )
        if s.onScroll != nil:
          s.onScroll(s.scrollPos.value)
        return

method center*(s: UIScroll, parent_rect: Rect): Vector2 =
  var
    parent_rect_moved = parent_rect
  
  parent_rect_moved.x -= s.scrollPos.value.x
  parent_rect_moved.y -= s.scrollPos.value.y

  var bounds = s.bounds.toRect(parent_rect_moved)

  if s.height > s.vpHeight:
    bounds.width -= 80

  ## returns true if you can focus the element
  for e in s.elements:
    if not e.isActive: continue

    if e.focused:
      return e.center(bounds)

method update*(s: UIScroll, parentRect: Rect, mousePos: Vector2, dt: float32, active: bool) =
  if active and s.isActive:
    s.scrollPos.value = newVector2(
      clamp(s.scrollPos.value.x, 0, max(s.height - s.vpHeight, 0.0)),
      clamp(s.scrollPos.value.y, 0, max(s.height - s.vpHeight, 0.0)),
    )
    s.scrollVis = lerp(s.scrollVis, s.scrollPos.value, clamp(dt * s.smooth, 0, 1))
    s.scrollVis.y = clamp(s.scrollVis.y, 0.0, s.height)
  else:
    s.scrollVis = s.scrollPos.value
    s.scrollVis.y = clamp(s.scrollVis.y, 0.0, s.height)

  var parent_rect_moved = parent_rect

  parent_rect_moved.x -= s.scrollVis.x
  parent_rect_moved.y -= s.scrollVis.y

  var bounds = s.bounds.toRect(parent_rect_moved)

  if s.height > s.vpHeight:
    bounds.width -= 80

  for i in 0..<s.elements.len:
    s.elements[i].update(bounds, mousePos, dt, s.isActive and active and mousePos in bounds)

method propagate*(s: UIScroll): bool =
  if s.scrollClick:
    return true

  for i in 0..<s.elements.len:
    if s.elements[i].propagate():
      template e: untyped = s.elements[i]

      let
        min_y = e.bounds.YMin + e.bounds.anchorYMin * s.vpHeight
        max_y = e.bounds.YMax + e.bounds.anchorYMax * s.vpHeight

        y = (min_y + max_y) / 2

        diff = s.scrollVis.y -
          (y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0))
  
      for j in 0..<s.elements.len:
        s.elements[j].moveCenter(newVector2(0, diff))

      s.scrollPos.value = newVector2(
        s.scrollPos.value.x,
        (y - s.vpHeight / 2).clamp(0, max(s.height - s.vpHeight, 0)),
      )
      if s.onScroll != nil:
        s.onScroll(s.scrollPos.value)
      result = true

method updateTooltip*(s: UIScroll, dt: float32) =
  for e in s.elements:
    if s.inside == false:
      e.tooltipTimer = 0.0
    else:
      e.updateTooltip(dt)

method drawDebug*(s: UIScroll, parent_rect: Rect) =
  var
    parent_rect_moved = parent_rect

  parent_rect_moved.x -= s.scrollVis.x
  parent_rect_moved.y -= s.scrollVis.y

  let vp = s.bounds.toRect(parent_rect)

  var bounds = s.bounds.toRect(parent_rect_moved)

  bounds.width -= 80

  if s.scrollFocus:
    drawRectOutline(
      newRect(
        vp.x + vp.width - 80.0,
        vp.y,
        80.0,
        vp.height,
      ),
      5,
      COLOR_GREEN,
    )
  if s.inside:
    drawRectOutline(
      vp,
      5,
      COLOR_BLUE,
    )
  else:
    drawRectOutline(
      vp,
      5,
      COLOR_RED,
    )

  for e in s.elements:
    if e.isActive:
      e.drawDebug(bounds)