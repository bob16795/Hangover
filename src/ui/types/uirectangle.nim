import core/types/rect

type
  UIRectangle* = object
    ## a ui rectangle, allows you to set anchors based off ratios of a parent rectangle
    empty: bool
    XMin*, YMin*: float32
    XMax*, YMax*: float32
    anchorXMin*, anchorYMin*: float32
    anchorXMax*, anchorYMax*: float32

proc toRect*(rect: UIRectangle, parent: Rect): Rect =
  ## converts the UIRectangle to a Rect
  var
    axmin = parent.x.float32 + (parent.width.float32 * rect.anchorXMin)
    aymin = parent.y.float32 + (parent.height.float32 * rect.anchorYMin)
    axmax = parent.x.float32 + (parent.width.float32 * rect.anchorXMax)
    aymax = parent.y.float32 + (parent.height.float32 * rect.anchorYMax)
  result.x = rect.XMin + axmin
  result.y = rect.YMin + aymin
  result.width = rect.XMax + axmax - rect.Xmin - axmin
  result.height = rect.YMax + aymax - rect.Ymin - aymin
  result = result.fix()

proc newUIRectangle*(XMin, YMin: float32, XMax, YMax: float32, anchorXMin,
    anchorYMin: float32, anchorXMax, anchorYMax: float32): UIRectangle =
  ## creates a new UIRectangle
  result.Xmin = Xmin
  result.Xmax = Xmax
  result.Ymin = Ymin
  result.Ymax = Ymax
  result.anchorXMin = anchorXMin
  result.anchorXMax = anchorXMax
  result.anchorYMin = anchorYMin
  result.anchorYMax = anchorYMax
