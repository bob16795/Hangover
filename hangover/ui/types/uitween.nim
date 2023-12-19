import hangover/ui/types/uirectangle
import hangover/core/types/rect
import sugar
import math

type
  UITween* = ref object of UIRectangle
    startRect: UIRectangle
    endRect: UIRectangle
    interpolate: (a: UIRectangle, b: UIRectangle, pc: float32) -> UIRectangle
    timeLeft*: float32
    totalTime*: float32

var
  tweens*: seq[UITween]

const
    c1 = 1.70158
    c3 = c1 + 1

template lerp(a, b, pc: untyped): untyped =
  a + (b - a) * pc

proc defaultInterpolate*(a, b: UIRectangle, x: float32): UIRectangle =
  result = UIRectangle()

  let pc = clamp(1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2), 0, 1)

  # set offsets
  result.Xmin = lerp(a.Xmin, b.Xmin, pc)
  result.Xmax = lerp(a.Xmax, b.Xmax, pc)
  result.Ymin = lerp(a.Ymin, b.Ymin, pc)
  result.Ymax = lerp(a.Ymax, b.Ymax, pc)

  # set anchors
  result.anchorXMin = lerp(a.anchorXMin, b.anchorXMin, pc)
  result.anchorXMax = lerp(a.anchorXMax, b.anchorXMax, pc)
  result.anchorYMin = lerp(a.anchorYMin, b.anchorYMin, pc)
  result.anchorYMax = lerp(a.anchorYMax, b.anchorYMax, pc)

proc newUITween*(a, b: UIRectangle, time: float32): UITween =
  result = UITween()
  result.startRect = a
  result.endRect = b

  result.timeLeft = time
  result.totalTime = time

  result.interpolate = defaultInterpolate

  tweens &= result

proc update*(t: UITween, dt: float32) =
  t.timeLeft -= dt
  t.timeLeft = max(0, t.timeLeft)

proc reset*(t: UITween) =
  t.timeLeft = t.totalTime

method toRect*(t: UITween, parent: Rect): Rect =
  var pc = 1.0 - (t.timeLeft / t.totalTime)
  result = t.interpolate(t.startRect, t.endRect, pc).toRect(parent)
