import rendering/sprite
import core/types/texture
import core/types/point
import core/types/vector2
import core/types/color
import core/types/rect

type
  UIFillMode* = enum
    FM_TILE
    FM_STRETCH
    FM_NONE
  UISprite* = object of Sprite
    ## a ui sprite, renders in 8 elements
    renderSecs: array[0..2, array[0..2, Rect]]
    center: Rect
    fillMode: UIFillMode
    scale: Vector2
    layer: range[0..500]
var
  uiSpriteScaleMult*: float32 = 1

proc setCenter(sprite: var UISprite, center: Rect) =
  sprite.center = center
  for i in 0..2:
    sprite.renderSecs[0][i].x = sprite.sourceBounds.x
    sprite.renderSecs[0][i].width = sprite.center.x - sprite.sourceBounds.x
    sprite.renderSecs[1][i].x = sprite.center.x
    sprite.renderSecs[1][i].width = sprite.center.width
    sprite.renderSecs[2][i].x = sprite.center.x + sprite.center.width
    sprite.renderSecs[2][i].width = (sprite.sourceBounds.x +
            sprite.sourceBounds.width) - (sprite.center.x +
            sprite.center.width)
    sprite.renderSecs[i][0].y = sprite.sourceBounds.y
    sprite.renderSecs[i][0].height = center.y - sprite.sourceBounds.y
    sprite.renderSecs[i][1].y = sprite.center.y
    sprite.renderSecs[i][1].height = sprite.center.height
    sprite.renderSecs[i][2].y = sprite.center.y + sprite.center.height
    sprite.renderSecs[i][2].height = (sprite.sourceBounds.y +
            sprite.sourceBounds.height) - (sprite.center.y +
            sprite.center.height)

proc newUISprite*(texture: Texture, sourceBounds,
        center: Rect): UISprite =
  result.texture = texture
  result.sourceBounds = sourceBounds
  result.scale = newVector2(1, 1)
  result.setCenter(center)

proc range(start, stop, step: int): seq[int] =
  var i = start
  while i < stop:
    result.add(i)
    i += step

proc scale*(sprite: UISprite, scale: Vector2): UISprite =
  ## sets the scale of the UISprite
  result = sprite
  result.scale = scale

proc drawSec*(sprite: var UISprite, src: Point, dest: var Rect, c: Color, layer: range[0..500]) =
  var renderSec = sprite.renderSecs[src.x][src.y]
  var dest = dest.offset(newVector2(-1, -1))
  dest.width += 2
  dest.height += 2
  sprite.texture.draw(renderSec, dest, color = c, layer = layer)

proc draw*(sprite: var UISprite, renderRect: Rect, c: Color = newColor(255, 255,
           255, 255), layer: range[0..500] = 0) =
  ## draws the UISprite

  # too small to draw
  var minSize = (sprite.sourceBounds.size - sprite.center.size)
  minSize.x *= sprite.scale.x * uiSpriteScaleMult
  minSize.y *= sprite.scale.y * uiSpriteScaleMult
  if renderRect.width <= minSize.x or renderRect.height <= minSize.y:
    sprite.draw(renderRect, 0, color = c, layer = layer)
    return 
  
  # no center defined
  if sprite.center.width == 0 or sprite.center.height == 0: return

  var tmp: Rect
  var rrtmp = newRect(
    renderRect.x.float32,
    renderRect.y.float32,
    renderRect.width.float32,
    renderRect.height.float32,
  )

  var corners: Vector2
  corners.x = (sprite.renderSecs[0][0].size + sprite.renderSecs[2][2].size).x * sprite.scale.x * uiSpriteScaleMult
  corners.y = (sprite.renderSecs[0][0].size + sprite.renderSecs[2][2].size).y * sprite.scale.y * uiSpriteScaleMult
  var corner: Vector2
  corner.x = sprite.renderSecs[0][0].size.x * sprite.scale.x * uiSpriteScaleMult
  corner.y = sprite.renderSecs[0][0].size.y * sprite.scale.y * uiSpriteScaleMult

  tmp = sprite.renderSecs[0][0]
  tmp.location = newVector2(rrtmp.x, rrtmp.y)
  tmp.width *= sprite.scale.x * uiSpriteScaleMult
  tmp.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(0, 0), tmp, c, layer)

  tmp = sprite.renderSecs[1][0]
  tmp.location = newVector2(rrtmp.x + corner.x, rrtmp.y)
  tmp.width = rrtmp.width - corners.x
  tmp.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(1, 0), tmp, c, layer)

  tmp = sprite.renderSecs[2][0]
  tmp.location = newVector2((rrtmp.x + rrtmp.width) - sprite.renderSecs[2][
          0].width * sprite.scale.x * uiSpriteScaleMult, rrtmp.y)
  tmp.width *= sprite.scale.x * uiSpriteScaleMult
  tmp.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(2, 0), tmp, c, layer)

  tmp = sprite.renderSecs[0][1]
  tmp.location = newVector2(rrtmp.x, rrtmp.y + corner.y)
  tmp.width *= sprite.scale.x * uiSpriteScaleMult
  tmp.height = rrtmp.height - corners.y
  sprite.drawSec(newPoint(0, 1), tmp, c, layer)

  tmp = sprite.renderSecs[1][1]
  tmp.location = newVector2(rrtmp.x + corner.x, rrtmp.y + corner.y)
  tmp.width = rrtmp.width - corners.x
  tmp.height = rrtmp.height - corners.y
  sprite.drawSec(newPoint(1, 1), tmp, c, layer)

  tmp = sprite.renderSecs[2][1]
  tmp.location = newVector2((rrtmp.x + rrtmp.width) - sprite.renderSecs[2][
          0].width * sprite.scale.x * uiSpriteScaleMult, rrtmp.y + corner.y)
  tmp.width *= sprite.scale.x * uiSpriteScaleMult
  tmp.height = rrtmp.height - corners.y
  sprite.drawSec(newPoint(2, 1), tmp, c, layer)

  tmp = sprite.renderSecs[0][2]
  tmp.location = newVector2(rrtmp.x, (rrtmp.y + rrtmp.height) - sprite.renderSecs[0][
          2].height * sprite.scale.y * uiSpriteScaleMult)
  tmp.width *= sprite.scale.x * uiSpriteScaleMult
  tmp.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(0, 2), tmp, c, layer)

  tmp = sprite.renderSecs[1][2]
  tmp.location = newVector2(rrtmp.x + corner.x, (rrtmp.y + rrtmp.height) - sprite.renderSecs[0][
          2].height * sprite.scale.y * uiSpriteScaleMult)
  tmp.width = rrtmp.width - corners.x
  tmp.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(1, 2), tmp, c, layer)

  tmp = sprite.renderSecs[2][2]
  tmp.location = newVector2((rrtmp.x + rrtmp.width) - sprite.renderSecs[2][
          0].width * sprite.scale.x * uiSpriteScaleMult, (rrtmp.y + rrtmp.height) -
              sprite.renderSecs[0][
          2].height * sprite.scale.y * uiSpriteScaleMult)
  tmp.width *= sprite.scale.x * uiSpriteScaleMult
  tmp.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(2, 2), tmp, c, layer)
