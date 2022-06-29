when not defined(ginGLFM):
  import freetype/freetype
  import freetype/fttypes
import opengl
import point
import color
import shader
import vector2
import texture
import rect

type
  Font* = object

    when not defined(ginGLFM):
      face: FT_Face
    texture*: GLuint
    size*: int
    characters: array[0..128, Character]
    spacing: int
    border*: float32
  Character* = object
    tx: GLfloat
    tw: GLfloat
    th: GLfloat
    bearing: Point
    advance: int
    ay: int
    size: Point

const
  vertexCode = """
layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 tintColorIn;

uniform mat4 projection;
out vec2 texCoords;
out vec4 tintColor;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    texCoords = vertex.zw;
    tintColor = tintColorIn;
}
"""
  fragmentCode = """
in vec2 texCoords;
in vec4 tintColor;

out vec4 color;

uniform sampler2D text;

void main()
{    
    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(text, texCoords).r);
    color = tintColor * sampled;
}
"""
when not defined(ginGLFM):
  var ft: FT_Library
var
  fontProgram*: Shader

proc initFT*() =
  when not defined(ginGLFM):
    if init(ft).int != 0:
      quit "failed to load font library"

    fontProgram = newShader(vertexCode, fragmentCode)
    fontProgram.registerParam("projection", SPKProj4)
    fontProgram.registerParam("tintColor", SPKFloat4)

proc deinitFT*() =
  when not defined(ginGLFM):
    discard FT_Done_FreeType(ft)


proc finFont*(f: Font, size: int): Font =
  when not defined(ginGLFM):
    result = f
    discard FT_Set_Pixel_Sizes(result.face, 0, size.cuint)

    template g: untyped = result.face.glyph


    var atlasSize = newPoint(0, 0)
    for c in 0..<128:
      if FT_Load_Char(result.face, c.culong, FT_LOAD_RENDER).int != 0:
        echo "failed to load glyph '" & c.char & "'"
        continue
      atlasSize.x += g.bitmap.width.cint
      atlasSize.y = max(atlasSize.y, g.bitmap.rows.cint)

    glActiveTexture(GL_TEXTURE0)
    glGenTextures(1, addr result.texture)
    glBindTexture(GL_TEXTURE_2D, result.texture)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED.GLint, atlasSize.x.GLsizei,
        atlasSize.y.GLsizei, 0, GL_RED, GL_UNSIGNED_BYTE, cast[pointer](0))

    result.size = atlasSize.y

    var x: cuint

    for c in 0..<128:
      if FT_Load_Char(result.face, c.culong, FT_LOAD_RENDER).int != 0:
        continue

      glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, 0, g.bitmap.width.GLsizei,
          g.bitmap.rows.GLsizei, GL_RED, GL_UNSIGNED_BYTE, g.bitmap.buffer)

      result.characters[c.int] = Character(
        size: newPoint(result.face.glyph.bitmap.width.cint,
            result.face.glyph.bitmap.rows.cint),
        bearing: newPoint(result.face.glyph.bitmap_left,
            result.face.glyph.bitmap_top),
        advance: result.face.glyph.advance.x,
        ay: result.face.glyph.advance.y,
        tx: x.float32 / atlasSize.x.float32,
        tw: g.bitmap.width.float32 / atlasSize.x.float32,
        th: g.bitmap.rows.float32 / atlasSize.y.float32,
      )
      x += g.bitmap.width
    glBindTexture(GL_TEXTURE_2D, 0)
    discard FT_Done_Face(result.face)

proc newFontMem*(data: cstring, dataSize: int64, size: int, spacing: int = 0): Font =
  when not defined(ginGLFM):
    if FT_New_Memory_Face(ft, data, cast[FT_Long](dataSize), 0, result.face).int != 0:
      quit "failed to load font"
    result = finFont(result, size)
    result.spacing = spacing

proc newFont*(face: string, size: int, spacing: int = 0): Font =
  when not defined(ginGLFM):
    if FT_New_Face(ft, face, 0, result.face).int != 0:
      quit "failed to load font"
    result = finFont(result, size)
    result.spacing = spacing

proc draw*(font: Font, text: string, position: Point, color: Color, scale: float32 = 1, layer: range[0..500] = 0) =
  when not defined(ginGLFM):
    var pos = position

    var srect = newRect(0, 0, 1, 1)
    for c in text:
      if not font.characters.len > c.int: continue
      var
        ch = font.characters[c.int]
        w = (ch.size.x.float32 * scale).cint
        h = (ch.size.y.float32 * scale).cint
        xpos = pos.x + ((ch.bearing.x).float32 * scale).cint
        ypos = pos.y - ((ch.bearing.y).float32 * scale).cint + (font.size.float32 * scale).cint
      srect.x = ch.tx
      srect.width = ch.tw
      srect.height = ch.th

      # render texture
      var tex = Texture(tex: font.texture)
      tex.draw(srect, newRect(xpos.float32 - font.border, ypos.float32 - font.border, w.float32 + 2 * font.border,
          h.float32 + 2 * font.border), addr fontProgram, color, layer = layer)
      pos.x += ((ch.advance shr 6).float32 * scale).cint
      pos.x += font.spacing + (2 * font.border).cint

proc sizeText*(font: Font, text: string, scale: float32 = 1): Vector2 =
  when not defined(ginGLFM):
    for c in text:
      if not font.characters.len > c.int: continue
      var
        ch = font.characters[c.int]
      result.x += ((ch.advance shr 6).float32 * scale)
      result.x += font.spacing.float32 + (2 * font.border).float32
    result.y = font.size.float32
