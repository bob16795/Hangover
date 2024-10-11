import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/loop
import options
import opengl
import math

var
  shapeTexture*: Texture

proc setupShapeTexture*() =
  let data = [newColor(255, 255, 255)]
  shapeTexture = newTexture(newVector2(1, 1))
  withGraphics:
    glBindTexture(GL_TEXTURE_2D, shapeTexture.tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, 1, 1,
      0, GL_RGBA, GL_UNSIGNED_BYTE, addr data)
    glGenerateMipmap(GL_TEXTURE_2D)

proc drawRectOutline*(r: Rect, width: int, c: Color, contrast: ContrastEntry = ContrastEntry(mode: fg)) =
  block:
    var tmp = r
    tmp.width = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c, contrast = contrast)

  block:
    var tmp = r
    tmp.height = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c, contrast = contrast)

  block:
    var tmp = r
    tmp.x += tmp.width - width.float32
    tmp.width = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c, contrast = contrast)

  block:
    var tmp = r
    tmp.y += tmp.height - width.float32
    tmp.height = width.float32
    shapeTexture.draw(newRect(0, 0, 1, 1), tmp, color = c, contrast = contrast)

proc drawRectFill*(r: Rect, c: Color, contrast: ContrastEntry = ContrastEntry(mode: fg)) =
  shapeTexture.draw(newRect(0, 0, 1, 1), r, color = c, contrast = contrast)

proc drawPoly*(points: seq[Vector2], c: Color) =
  var center = newVector2(0, 0)
  for point in points:
    center += point
  center /= points.len - 1

proc drawLine*(a, b: Vector2, thickness: float32, c: Color, contrast: ContrastEntry = ContrastEntry(mode: fg)) =
  var verts: seq[array[16, float32]]
  let
    length = distance(a, b)
    dx = (b.x - a.x) / length
    dy = (b.y - a.y) / length

    px = 0.5 * thickness * -dy
    py = 0.5 * thickness * dx

  verts &= [(a.x + px).float32, a.y + py, 0.0, 0.0, c.rf, c.gf, c.bf, c.af, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  verts &= [(b.x - px).float32, b.y - py, 0.0, 0.0, c.rf, c.gf, c.bf, c.af, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  verts &= [(b.x + px).float32, b.y + py, 0.0, 0.0, c.rf, c.gf, c.bf, c.af, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

  verts &= [(a.x + px).float32, a.y + py, 0.0, 0.0, c.rf, c.gf, c.bf, c.af, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  verts &= [(b.x - px).float32, b.y - py, 0.0, 0.0, c.rf, c.gf, c.bf, c.af, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
  verts &= [(a.x - px).float32, a.y - py, 0.0, 0.0, c.rf, c.gf, c.bf, c.af, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

  shapeTexture.drawVerts(verts, color = c, contrast = contrast)

proc drawCircleOutline*(center: Vector2, radius: float32, thickness: float32, c: Color) =
  var
    x = center.x + cos(0.float32) * radius
    y = center.y + sin(0.float32) * radius

  for i in 0..50:
    let
      nx = center.x + cos(2 * PI * i.float32 / 20) * radius
      ny = center.y + sin(2 * PI * i.float32 / 20) * radius

    drawLine(newVector2(x, y), newVector2(nx, ny), thickness, c)

    x = nx
    y = ny
