import hangover/ui/types/uirectangle
import hangover/core/types/rect
import hangover/core/types/vector2
import sugar
import math

type
  UIBobber* = ref object of UIRectangle
    pos: Rect
    amp: float32
    freq: float32
    timer: float32
    ampMult: float32
    offset: Vector2
    voffset: Vector2
    size: float32
    grow: float32
    always: bool
    focusable: bool
    keepBounds: Rect

var
  bobbers*: seq[UIBobber]
  noBobbing* = false
  bobberScreen*: Vector2

proc newUIBobber*(XMin, YMin: float32, XMax, YMax: float32, anchorXMin,
                  anchorYMin: float32, anchorXMax, anchorYMax: float32,
                  always: bool = false, focus: bool = true): UIBobber =
  result = UIBobber()

  # set offsets
  result.Xmin = Xmin
  result.Xmax = Xmax
  result.Ymin = Ymin
  result.Ymax = Ymax

  # set anchors
  result.anchorXMin = anchorXMin
  result.anchorXMax = anchorXMax
  result.anchorYMin = anchorYMin
  result.anchorYMax = anchorYMax

  result.amp = 14.0
  result.freq = 2.0
  result.grow = 15
  result.focusable = focus
  result.always = always

  bobbers &= result

proc update*(b: UIBobber, dt: float32, mouse: Vector2) =
  if dt == 0.0:
    return

  if (b.always or mouse in b.pos) and b.focusable:
    b.ampMult += dt * 5
  else:
    b.ampMult -= dt * 5

  b.timer += dt

  b.ampMult = clamp(b.ampMult, 0, 1)

  b.offset.y = sin(b.timer * 2 * PI / b.freq) * b.amp * b.ampMult * 0.5
  b.offset.x = 0

  if (b.always or mouse in b.pos) and b.focusable:
    b.offset.y += clamp(mouse.y - b.pos.center.y, -b.pos.height, b.pos.height) /
        (b.pos.height / b.amp)

    b.offset.x += clamp(mouse.x - b.pos.center.x, -b.pos.width, b.pos.width) / (
        b.pos.width / b.amp)
  else:
    b.offset *= 0.5

  b.voffset = lerp(b.voffset, b.offset, clamp(dt * 5, 0, 1))

  b.size = b.ampMult * b.grow

proc newUIBobber*(b: UIRectangle, always: bool = false,
    focus: bool = true): UIBobber =
  result = UIBobber()

  # set offsets
  result.Xmin = b.Xmin
  result.Xmax = b.Xmax
  result.Ymin = b.Ymin
  result.Ymax = b.Ymax

  # set anchors
  result.anchorXMin = b.anchorXMin
  result.anchorXMax = b.anchorXMax
  result.anchorYMin = b.anchorYMin
  result.anchorYMax = b.anchorYMax

  result.amp = 14.0
  result.freq = 2.0
  result.grow = 15
  result.focusable = focus
  result.always = always

  bobbers &= result

method toRect*(b: var UIBobber, parent: Rect): Rect =
  ## converts the UIRectangle to a Rect

  # calculate anchored positions
  let
    axmin = parent.x.float32 + (parent.width.float32 * b.anchorXMin)
    aymin = parent.y.float32 + (parent.height.float32 * b.anchorYMin)
    axmax = parent.x.float32 + (parent.width.float32 * b.anchorXMax)
    aymax = parent.y.float32 + (parent.height.float32 * b.anchorYMax)

  # offset positions
  result.x = b.XMin + axmin
  result.y = b.YMin + aymin
  result.width = b.XMax + axmax - b.Xmin - axmin
  result.height = b.YMax + aymax - b.Ymin - aymin

  # fix rect
  if rectUpdate:
    b.pos = result.fix()
    b.lastCenter = result.center

  if noBobbing:
    return result

  let
    noFix = result.x + result.width > bobberScreen.x or
        result.y + result.height > bobberScreen.y

  # offset with bob
  result = b.pos.offset(b.voffset)
  result.x -= b.size / 2.0
  result.y -= b.size / 2.0
  result.width += b.size
  result.height += b.size

  if not noFix:
    result.x = clamp(result.x, 0, bobberScreen.x - result.width)
    result.y = clamp(result.y, 0, bobberScreen.y - result.height)
