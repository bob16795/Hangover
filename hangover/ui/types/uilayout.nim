import hangover/core/types/vector2
import hangover/ui/types/uirectangle

type
    UILayoutUIRectangleype* = enum
        Vertical
        Horizontal

    UILayoutData* = object
        fullSize*: Vector2
        case kind*: UILayoutUIRectangleype
        of Vertical:
            offsetVertical*: float32
        of Horizontal:
            offsetHorizontal*: float32

    UILayout* = ref object
        first: UIRectangle
        curr: UIRectangle
        prev: UIRectangle
        data*: UILayoutData

proc applyUIRectangle*(layout: var UILayoutData,
        base: UIRectangle): UIRectangle =
    new(result)
    result[] = base[]
    case layout.kind:
    of Vertical:
        result.YMin += layout.offsetVertical
        result.YMax += layout.offsetVertical
        layout.fullSize.y += layout.offsetVertical
    of Horizontal:
        result.XMin += layout.offsetHorizontal
        result.XMax += layout.offsetHorizontal
        layout.fullSize.x += layout.offsetHorizontal

proc newLayout*(base: UIRectangle, data: UILayoutData): UILayout =
    return UILayout(
        first: base,
        curr: base,
        data: data,
    )

proc next*(self: UILayout, aStart: float32 = 0.0,
        aEnd: float32 = 1.0): UIRectangle =
    new(result)
    result[] = self.curr[]

    self.prev = UIRectangle()
    self.prev[] = self.curr[]
    case self.data.kind:
    of Vertical:
        let
            start = result.anchorXMin
            dist = result.anchorXMax - result.anchorXMin
        result.anchorXMin = start + dist * aStart
        result.anchorXMax = start + dist * aEnd
    of Horizontal:
        let
            start = result.anchorYMin
            dist = result.anchorYMax - result.anchorYMin
        result.anchorYMin = start + dist * aStart
        result.anchorYMax = start + dist * aEnd

    self.curr = self.data.applyUIRectangle(self.curr)

proc curr*(self: UILayout, aStart: float32 = 0.0,
        aEnd: float32 = 1.0): UIRectangle =
    new(result)
    result[] = self.prev[]
    case self.data.kind:
    of Vertical:
        let
            start = result.anchorXMin
            dist = result.anchorXMax - result.anchorXMin
        result.anchorXMin = start + dist * aStart
        result.anchorXMax = start + dist * aEnd
    of Horizontal:
        let
            start = result.anchorYMin
            dist = result.anchorYMax - result.anchorYMin
        result.anchorYMin = start + dist * aStart
        result.anchorYMax = start + dist * aEnd

proc first*(self: UILayout, aStart: float32 = 0.0, aEnd: float32 = 1.0): UIRectangle =
  self.curr[] = self.first[]
  self.prev = nil
  return self.next(aStart, aEnd)
