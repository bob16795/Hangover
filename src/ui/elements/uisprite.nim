import rendering/sprite
import core/types/texture
import core/types/point
import core/types/vector2
import core/types/rect

type
  UIFillMode* = enum
    FM_TILE
    FM_STRETCH
    FM_NONE
  UISprite* = object of Sprite
    renderSecs: array[0..2, array[0..2, Rect]]
    center: Rect
    fillMode: UIFillMode
    scale: float32

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
  result.scale = 1
  result.setCenter(center)

proc range(start, stop, step: int): seq[int] =
  var i = start
  while i < stop:
    result.add(i)
    i += step

proc scale*(sprite: UISprite, scale: float32): UISprite =
  result = sprite
  result.scale = scale

proc drawSec*(sprite: var UISprite, src: Point, dest: var Rect) =
  var lol = sprite.renderSecs[src.x][src.y]
  sprite.texture.draw(lol, dest)

proc draw*(sprite: var UISprite, renderRect: Rect) =
  if sprite.center.width == 0 or sprite.center.height == 0:
    return
  var tmp: Rect
  var rrtmp = renderRect

  var corners = (sprite.renderSecs[0][0].size + sprite.renderSecs[2][2].size) * sprite.scale
  var corner = sprite.renderSecs[0][0].size * sprite.scale

  tmp = sprite.renderSecs[0][0]
  tmp.location = newVector2(rrtmp.x, rrtmp.y)
  tmp.width *= sprite.scale
  tmp.height *= sprite.scale
  sprite.drawSec(newPoint(0, 0), tmp)

  tmp = sprite.renderSecs[1][0]
  tmp.location = newVector2(rrtmp.x + corner.x, rrtmp.y)
  tmp.width = rrtmp.width - corners.x
  tmp.height *= sprite.scale
  sprite.drawSec(newPoint(1, 0), tmp)

  tmp = sprite.renderSecs[2][0]
  tmp.location = newVector2((rrtmp.x + rrtmp.width) - sprite.renderSecs[2][
          0].width * sprite.scale, rrtmp.y)
  tmp.width *= sprite.scale
  tmp.height *= sprite.scale
  sprite.drawSec(newPoint(2, 0), tmp)

  tmp = sprite.renderSecs[0][1]
  tmp.location = newVector2(rrtmp.x, rrtmp.y + corner.y)
  tmp.width *= sprite.scale
  tmp.height = rrtmp.height - corners.y
  sprite.drawSec(newPoint(0, 1), tmp)

  tmp = sprite.renderSecs[1][1]
  tmp.location = newVector2(rrtmp.x + corner.x, rrtmp.y + corner.y)
  tmp.width = rrtmp.width - corners.x
  tmp.height = rrtmp.height - corners.y
  sprite.drawSec(newPoint(1, 1), tmp)

  tmp = sprite.renderSecs[2][1]
  tmp.location = newVector2((rrtmp.x + rrtmp.width) - sprite.renderSecs[2][
          0].width * sprite.scale, rrtmp.y + corner.y)
  tmp.width *= sprite.scale
  tmp.height = rrtmp.height - corners.y
  sprite.drawSec(newPoint(2, 1), tmp)

  tmp = sprite.renderSecs[0][2]
  tmp.location = newVector2(rrtmp.x, (rrtmp.y + rrtmp.height) - sprite.renderSecs[0][
          2].height * sprite.scale)
  tmp.width *= sprite.scale
  tmp.height *= sprite.scale
  sprite.drawSec(newPoint(0, 2), tmp)

  tmp = sprite.renderSecs[1][2]
  tmp.location = newVector2(rrtmp.x + corner.x, (rrtmp.y + rrtmp.height) - sprite.renderSecs[0][
          2].height * sprite.scale)
  tmp.width = rrtmp.width - corners.x
  tmp.height *= sprite.scale
  sprite.drawSec(newPoint(1, 2), tmp)

  tmp = sprite.renderSecs[2][2]
  tmp.location = newVector2((rrtmp.x + rrtmp.width) - sprite.renderSecs[2][
          0].width * sprite.scale, (rrtmp.y + rrtmp.height) - sprite.renderSecs[
              0][
          2].height * sprite.scale)
  tmp.width *= sprite.scale
  tmp.height *= sprite.scale
  sprite.drawSec(newPoint(2, 2), tmp)
