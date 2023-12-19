import hangover/core/types/rect


type
  UIRectangle* = ref object of RootObj
    ## a ui rectangle, allows you to set anchors based off ratios of a parent rectangle
    empty: bool
    XMin*, YMin*: float32 ## min offsets
    XMax*, YMax*: float32 ## max offsets
    anchorXMin*, anchorYMin*: float32 ## min anchors
    anchorXMax*, anchorYMax*: float32 ## max anchor2

method toRect*(rect: UIRectangle, parent: Rect): Rect {.base.} =
  ## converts the UIRectangle to a Rect
  
  # calculate anchored positions
  let
    axmin = parent.x.float32 + (parent.width.float32 * rect.anchorXMin)
    aymin = parent.y.float32 + (parent.height.float32 * rect.anchorYMin)
    axmax = parent.x.float32 + (parent.width.float32 * rect.anchorXMax)
    aymax = parent.y.float32 + (parent.height.float32 * rect.anchorYMax)

  # offset positions
  result.x = rect.XMin + axmin
  result.y = rect.YMin + aymin
  result.width = rect.XMax + axmax - rect.Xmin - axmin
  result.height = rect.YMax + aymax - rect.Ymin - aymin

  # fix rect
  result = result.fix()

proc newUIRectangle*(XMin, YMin: float32, XMax, YMax: float32, anchorXMin,
    anchorYMin: float32, anchorXMax, anchorYMax: float32): UIRectangle =
  ## creates a new UIRectangle
  result = UIRectangle()

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
