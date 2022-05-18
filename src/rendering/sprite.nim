import core/types/texture
import core/types/vector2
import core/types/color
import core/types/point
import core/types/rect


type
  Sprite* = object of RootObj
    texture*: Texture
    sourceBounds*: Rect

proc newSprite*(texture: Texture, x, y, w, h: float32): Sprite =
  result.texture = texture
  result.sourceBounds = newRect(x, y, w, h)

proc newSprite*(texture: Texture, bounds: Rect): Sprite =
  result.texture = texture
  result.sourceBounds = bounds

proc draw*(sprite: Sprite, position: Vector2, rotation: float32,
    size: Vector2 = newVector2(0, 0), c: Color = newColor(255, 255, 255, 255)) =
  var trgSize = size
  if size == newVector2(0, 0):
    trgSize = sprite.sourceBounds.size
  sprite.texture.draw(sprite.sourceBounds, newRect(position,
                        trgSize), color = c, rotation = rotation)
