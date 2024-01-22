import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/color
import hangover/core/types/rect
import opengl

var
  shapeTexture: Texture

proc setupShapeTexture*() =
  let data = [newColor(255, 255, 255)]
  shapeTexture = newTexture(newVector2(1, 1))
  glBindTexture(GL_TEXTURE_2D, shapeTexture.tex)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, 1, 1,
    0, GL_RGBA, GL_UNSIGNED_BYTE, addr data)
  glGenerateMipmap(GL_TEXTURE_2D)

proc drawRectOutline*(r: Rect, width: int, c: Color) =
  block:
    var tmp = r
    tmp.width = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c)

  block:
    var tmp = r
    tmp.height = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c)

  block:
    var tmp = r
    tmp.x += tmp.width - width.float32
    tmp.width = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c)

  block:
    var tmp = r
    tmp.y += tmp.height - width.float32
    tmp.height = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c)

proc drawRectFill*(r: Rect, c: Color) =
  shapeTexture.draw(newRect(0, 0, 1, 1), r, color = c)
