import hangover/rendering/sprite
import hangover/core/types/texture
import hangover/core/types/point
import hangover/core/types/vector2
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/logging

## a 9 part sprite
##
## has render sections:
## a | b | c
## --+---+--
## d | e | f
## --+---+--
## g | h | i
##
## refered to later

type
  UIFillMode* = enum
    FM_STRETCH ## fast, stretches the element to 9 quads
    FM_TILE    ## slow, repeats sprites to make the element cleaner
  UISprite* = object of Sprite
    ## a ui sprite, renders in 8 elements
    renderSecs: array[0..2, array[0..2, Rect]]
    center: Rect
    fillMode: UIFillMode
    scale: Vector2
    layer: range[0..500]

var
  uiSpriteScaleMult*: float32 = 1
  uiScaleMult*: float32 = 1
  ## used to scale all uisprites further

proc setCenter(sprite: var UISprite, center: Rect) =
  ## sets the center of the sprite

  # set the center rect
  sprite.center = center

  # setup renderSecs
  for i in 0..2:
    # x and width

    # x of a, d, and g
    sprite.renderSecs[0][i].x = sprite.sourceBounds.x
    # width of a, d, and g
    sprite.renderSecs[0][i].width = sprite.center.x - sprite.sourceBounds.x
    # x of b, e, and h
    sprite.renderSecs[1][i].x = sprite.center.x
    # width of b, e, and h
    sprite.renderSecs[1][i].width = sprite.center.width
    # x of c, f, and i
    sprite.renderSecs[2][i].x = sprite.center.x + sprite.center.width
    # width of c, f, and i
    sprite.renderSecs[2][i].width = (sprite.sourceBounds.x +
            sprite.sourceBounds.width) - (sprite.center.x +
            sprite.center.width)

    # y and height

    # y of a, b, and c
    sprite.renderSecs[i][0].y = sprite.sourceBounds.y
    # height of a, b, and c
    sprite.renderSecs[i][0].height = center.y - sprite.sourceBounds.y
    # y of d, e, and f
    sprite.renderSecs[i][1].y = sprite.center.y
    # height of d, e, and f
    sprite.renderSecs[i][1].height = sprite.center.height
    # y of g, h, and i
    sprite.renderSecs[i][2].y = sprite.center.y + sprite.center.height
    # height of g, h, and i
    sprite.renderSecs[i][2].height = (sprite.sourceBounds.y +
            sprite.sourceBounds.height) - (sprite.center.y +
            sprite.center.height)

proc newUISprite*(texture: Texture, sourceBounds,
        center: Rect): UISprite =
  ## creates a ui Sprite

  # sets the texture
  result.texture = texture

  # set the source
  result.sourceBounds = sourceBounds

  # init the scale
  result.scale = newVector2(1, 1)

  # set the center
  result.setCenter(center)

proc range(start, stop, step: int): seq[int] =
  ## gets a range of numbers starting at start and ending at stop, stepping step
  var i = start
  while i < stop:
    result.add(i)
    i += step

proc scale*(sprite: UISprite, scale: Vector2): UISprite =
  ## sets the scale of the UISprite
  result = sprite
  result.scale = scale

# TODO: round better
proc drawSec(sprite: var UISprite, src: Point, dest: var Rect, c: Color,
    layer: range[0..500]) =
  ## renders a section of sprite

  # get the source bounds
  let renderSec = sprite.renderSecs[src.x][src.y]

  # get the dest
  var dest = dest.offset(newVector2(-1, -1))

  # add 2 to fix tearing
  dest.width += 2
  dest.height += 2
  sprite.texture.draw(renderSec, dest, color = c, layer = layer)

proc draw*(sprite: var UISprite, renderRect: Rect, c: Color = newColor(255, 255,
           255, 255), layer: range[0..500] = 0) =
  ## draws the UISprite

  # too small to draw a ui sprite
  var minSize = (sprite.sourceBounds.size - sprite.center.size)
  minSize.x *= sprite.scale.x # * uiSpriteScaleMult
  minSize.y *= sprite.scale.y # * uiSpriteScaleMult
  if renderRect.width <= minSize.x or renderRect.height <= minSize.y:
    #LOG_DEBUG("ho->uisprite", "bad size drawing normal")
    #sprite.draw(renderRect, 0, color = c, layer = layer)
    return

  # no center defined
  if sprite.center.width == 0 or sprite.center.height == 0:
    LOG_WARN("ho->uisprite", "no center defined not drawing sprite")
    return

  # init vars for drawing
  var
    destRect: Rect     # a temp destination rect
    tempDest: Rect     # stores render rect for modifing TODO: remove
    sideSizes: Vector2 # the size of the source rect minus the size of the center
    aSize: Vector2     # the size of the a segment

  # setup vars for drawing
  tempDest = newRect(
    renderRect.x.float32,
    renderRect.y.float32,
    renderRect.width.float32,
    renderRect.height.float32,
  )

  sideSizes.x = (sprite.renderSecs[0][0].size + sprite.renderSecs[2][
      2].size).x * sprite.scale.x * uiSpriteScaleMult
  sideSizes.y = (sprite.renderSecs[0][0].size + sprite.renderSecs[2][
      2].size).y * sprite.scale.y * uiSpriteScaleMult

  aSize.x = sprite.renderSecs[0][0].size.x * sprite.scale.x * uiSpriteScaleMult
  aSize.y = sprite.renderSecs[0][0].size.y * sprite.scale.y * uiSpriteScaleMult

  # draw segment a
  destRect = sprite.renderSecs[0][0]
  destRect.location = newVector2(tempDest.x, tempDest.y)
  destRect.width *= sprite.scale.x * uiSpriteScaleMult
  destRect.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(0, 0), destRect, c, layer)

  # draw segment b
  destRect = sprite.renderSecs[1][0]
  destRect.location = newVector2(tempDest.x + aSize.x, tempDest.y)
  destRect.width = tempDest.width - sideSizes.x
  destRect.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(1, 0), destRect, c, layer)

  # draw segment c
  destRect = sprite.renderSecs[2][0]
  destRect.location = newVector2((tempDest.x + tempDest.width) - sprite.renderSecs[2][
          0].width * sprite.scale.x * uiSpriteScaleMult, tempDest.y)
  destRect.width *= sprite.scale.x * uiSpriteScaleMult
  destRect.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(2, 0), destRect, c, layer)

  # draw segment d
  destRect = sprite.renderSecs[0][1]
  destRect.location = newVector2(tempDest.x, tempDest.y + aSize.y)
  destRect.width *= sprite.scale.x * uiSpriteScaleMult
  destRect.height = tempDest.height - sideSizes.y
  sprite.drawSec(newPoint(0, 1), destRect, c, layer)

  # draw segment f
  destRect = sprite.renderSecs[2][1]
  destRect.location = newVector2((tempDest.x + tempDest.width) - sprite.renderSecs[2][
          0].width * sprite.scale.x * uiSpriteScaleMult, tempDest.y + aSize.y)
  destRect.width *= sprite.scale.x * uiSpriteScaleMult
  destRect.height = tempDest.height - sideSizes.y
  sprite.drawSec(newPoint(2, 1), destRect, c, layer)

  # draw segment f
  destRect = sprite.renderSecs[0][2]
  destRect.location = newVector2(tempDest.x, (tempDest.y + tempDest.height) - sprite.renderSecs[0][
          2].height * sprite.scale.y * uiSpriteScaleMult)
  destRect.width *= sprite.scale.x * uiSpriteScaleMult
  destRect.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(0, 2), destRect, c, layer)

  # draw segment g
  destRect = sprite.renderSecs[1][2]
  destRect.location = newVector2(tempDest.x + aSize.x, (tempDest.y + tempDest.height) - sprite.renderSecs[0][
          2].height * sprite.scale.y * uiSpriteScaleMult)
  destRect.width = tempDest.width - sideSizes.x
  destRect.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(1, 2), destRect, c, layer)

  # draw segment h
  destRect = sprite.renderSecs[2][2]
  destRect.location = newVector2((tempDest.x + tempDest.width) - sprite.renderSecs[2][
          0].width * sprite.scale.x * uiSpriteScaleMult, (tempDest.y +
              tempDest.height) - sprite.renderSecs[0][
          2].height * sprite.scale.y * uiSpriteScaleMult)
  destRect.width *= sprite.scale.x * uiSpriteScaleMult
  destRect.height *= sprite.scale.y * uiSpriteScaleMult
  sprite.drawSec(newPoint(2, 2), destRect, c, layer)

  # draw segment e
  destRect = sprite.renderSecs[1][1]
  destRect.location = newVector2(tempDest.x + aSize.x, tempDest.y + aSize.y)
  destRect.width = tempDest.width - sideSizes.x
  destRect.height = tempDest.height - sideSizes.y
  sprite.drawSec(newPoint(1, 1), destRect, c, layer)
