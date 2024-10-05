import hangover/core/types/font
import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/ui/types/uisprite
import options

type
  UIToolTip* = ref object of RootObj
    text*: string
    font*: Font
    border*: UISprite
    color*: Color

proc draw*(t: UIToolTip, mousePos: Vector2, screenSize: Point) =
  let size = t.font.sizeText(t.text, 1.0)
  let pos = if mousePos.x + size.x + 40 < screenSize.x.float32:
      mousePos
    else:
      mousePos - newVector2(size.x + 40, 0.0)
  let hflip = not(mousePos.x + size.x + 40 < screenSize.x.float32)

  t.border.drawUISprite(newRect(pos, size + newVector2(40)), hflip = hflip, fg = some(true))
  t.font.draw(t.text, pos + newVector2(20), t.color, 1.0, fg = some(false))
