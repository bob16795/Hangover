import hangover/ui/types/uirectangle
import hangover/core/types/rect
import sugar

type
  UITween* = ref object of UIRectangle
    startRect: UIRectangle
    endRect: UIRectangle
    interpolate: (a: UIRectangle, b: UIRectangle, pc: float32) -> UIRectangle
    timeLeft*: float32
    totalTime*: float32

var
  tweens*: seq[UITween]

template lerp(a, b, pc: untyped): untyped =
  a + (b - a) * pc

proc defaultInterpolate*(a, b: UIRectangle, pc: float32): UIRectangle =
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
  result.endRect = a

  result.timeLeft = time
  result.totalTime = time

  tweens &= result

proc update*(t: UITween, dt: float32) =
  t.timeLeft -= dt
  t.timeLeft = max(0, t.timeLeft)

proc toRect*(t: UITween, parent: Rect): Rect =
  var pc = t.timeLeft / t.totalTime
  result = t.interpolate(t.startRect, t.endRect, pc).toRect(parent)
