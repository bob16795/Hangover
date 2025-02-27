import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/ui/elements/uielement
import hangover/ui/elements/uigroup
import hangover/ui/types/uisprite
import hangover/core/logging
import sugar

#TODO: comment

type
  UIRatioAlign* = enum
    Center, Start, End
  UIRatio* = ref object of UIGroup
    ratio*: float32
    align_x*: UIRatioAlign
    align_y*: UIRatioAlign

proc ratioParent(r: UIRatio, parent: Rect): Rect =
  result = parent

  if r.ratio != 0:
    let
      size = newVector2(r.ratio, 1)
      scale = min(
        parent.width / size.x,
        parent.height / size.y
      )

    result.size = size * scale
    result.x = case r.align_x:
                 of Start: parent.x
                 of Center: parent.center.x - result.width / 2
                 of End: parent.x + parent.width - result.width
    result.y = case r.align_y:
                 of Start: parent.y
                 of Center: parent.center.y - result.height / 2
                 of End: parent.y + parent.height - result.height

method checkHover*(r: UIRatio, parentRect: Rect, mousePos: Vector2) =
  procCall r.UIGroup.checkHover(r.ratioParent(parentRect), mousePos)

method update*(r: UIRatio, parentRect: Rect, mousePos: Vector2,
               dt: float32, active: bool) =
  procCall r.UIGroup.update(r.ratioParent(parentRect), mousePos,
                          dt, active)

method draw*(r: UIRatio, parentRect: Rect) =
  procCall r.UIGroup.draw(r.ratioParent(parentRect))

method navigate*(r: UIRatio, dir: UIDir, parentRect: Rect): bool =
  procCall r.UIGroup.navigate(dir, r.ratioParent(parentRect))

method center*(r: UIRatio, parentRect: Rect): Vector2 =
  let tmp = r.ratioParent(parentRect)

  (procCall r.UIGroup.center(tmp)) + parentRect.location - tmp.location
