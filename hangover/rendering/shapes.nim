import hangover/core/types/shader
import hangover/core/types/texture
import hangover/core/types/vector2
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/loop
import options
import opengl
import math

var
  shapeProgram* {.threadvar.}: Shader
  shapeTexture* {.threadvar.}: Texture

const
  shapeVertexCode* = """
layout (location = 0) in vec2 vertex;
layout (location = 1) in vec2 uv;

layout (location = 2) in vec2 srcOff;
layout (location = 3) in vec2 srcScl;

layout (location = 4) in vec2 dstOff;
layout (location = 5) in vec2 dstScl;

layout (location = 6) in vec3 rotation;
layout (location = 7) in vec4 tintColorIn;

uniform mat4 projection;

out vec2 texCoords;
out vec4 tintColor;

void main()
{
    vec2 r = (vertex * (1.0 + dstScl) - rotation.xy);
    vec2 g = vec2(sin(rotation.z), cos(rotation.z));
    r = vec2(
      r.x * g.y - r.y * g.x + rotation.x, 
      r.x * g.x + r.y * g.y + rotation.y 
    );

    gl_Position = projection * vec4(r + dstOff, 1.0, 1.0);
    texCoords = uv * (1.0 + srcScl) + srcOff;
    tintColor = tintColorIn;
}
"""
  shapeFragmentCode* = """
in vec2 texCoords;
in vec4 tintColor;

out vec4 color;

uniform sampler2D text;
uniform sampler2D contrast_tex;
uniform int contrast_override;
uniform int mode;
uniform float contrast;

void main()
{
  color = tintColor;
}
"""

proc setupShapeTexture*() =
  let data = [newColor(255, 255, 255)]
  shapeTexture = newTexture(newVector2(1, 1))
  withGraphics:
    glBindTexture(GL_TEXTURE_2D, shapeTexture.tex)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, 1, 1,
      0, GL_RGBA, GL_UNSIGNED_BYTE, addr data)
    glGenerateMipmap(GL_TEXTURE_2D)

  shapeProgram = newShader(shapeVertexCode, shapeFragmentCode)
  shapeProgram.registerParam("tintColor", SPKFloat4)
  shapeProgram.registerParam("projection", SPKProj4)
  shapeProgram.registerParam("rotation", SPKFloat1)
  shapeProgram.registerParam("contrast", SPKFloat1)
  shapeProgram.registerParam("contrast_override", SPKInt1)
  shapeProgram.registerParam("contrast_tex", SPKInt1)
  shapeProgram.registerParam("mode", SPKInt1)

proc drawRectOutline*(r: Rect, width: int, c: Color, contrast: ContrastEntry = ContrastEntry(mode: noContrast)) =
  block:
    var tmp = r
    tmp.width = width.float32
    shapeTexture.draw(
      newRect(0, 0, 1, 1),
      tmp,
      shader = shapeProgram,
      color = c,
      contrast = contrast,
    )

  block:
    var tmp = r
    tmp.height = width.float32
    shapeTexture.draw(
      newRect(0, 0, 1, 1),
      tmp,
      shader = shapeProgram,
      color = c,
      contrast = contrast,
    )

  block:
    var tmp = r
    tmp.x += tmp.width - width.float32
    tmp.width = width.float32
    shapeTexture.draw(
      newRect(0, 0, 1, 1),
      tmp,
      shader = shapeProgram,
      color = c,
      contrast = contrast,
    )

  block:
    var tmp = r
    tmp.y += tmp.height - width.float32
    tmp.height = width.float32
    shapeTexture.draw(
      newRect(0, 0, 1, 1),
      tmp,
      shader = shapeProgram,
      color = c,
      contrast = contrast,
    )

proc drawRectFill*(r: Rect, c: Color, contrast: ContrastEntry = ContrastEntry(mode: noContrast)) =
  shapeTexture.draw(
    newRect(0, 0, 1, 1),
    r,
    shader = shapeProgram,
    color = c,
    contrast = contrast,
  )

proc drawPoly*(points: seq[Vector2], c: Color) =
  var center = newVector2(0, 0)
  for point in points:
    center += point
  center /= points.len - 1

proc drawLine*(a, b: Vector2, thickness: float32, c: Color, contrast: ContrastEntry = ContrastEntry(mode: noContrast)) =
  var verts: seq[Vert]
  let
    length = distance(a, b)
    dx = (b.x - a.x) / length
    dy = (b.y - a.y) / length

    px = 0.5 * thickness * -dy
    py = 0.5 * thickness * dx

  verts &= Vert(
    x: (a.x + px).float32, y: a.y + py,
    r: c.rf, g: c.gf, b: c.bf, a: c.af
  )
  verts &= Vert(
    x: (b.x - px).float32, y: b.y - py,
    r: c.rf, g: c.gf, b: c.bf, a: c.af
  )
  verts &= Vert(
    x: (b.x + px).float32, y: b.y + py,
    r: c.rf, g: c.gf, b: c.bf, a: c.af
  )
  verts &= Vert(
    x: (a.x + px).float32, y: a.y + py, 
    r: c.rf, g: c.gf, b: c.bf, a: c.af
  )
  verts &= Vert(
    x: (b.x - px).float32, y: b.y - py, 
    r: c.rf, g: c.gf, b: c.bf, a: c.af
  )
  verts &= Vert(
    x: (a.x - px).float32, y: a.y - py, 
    r: c.rf, g: c.gf, b: c.bf, a: c.af
  )

  shapeTexture.drawVerts(
    verts,
    shader = shapeProgram,
    color = c,
    contrast = contrast,
  )

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
