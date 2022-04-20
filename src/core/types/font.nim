import freetype/freetype
import ../lib/gl
import point
import color
import shader
import vector2

type
  Font* = object
    face: FT_Face
    size: int
    characters: seq[Character]
  Character* = object
    id: GLuint
    size: Point
    bearing: Point
    advance: int

const
  vertexCode = """
#version 330 core
layout (location = 0) in vec4 vertex; // <vec2 pos, vec2 tex>
out vec2 TexCoords;

uniform mat4 projection;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    TexCoords = vertex.zw;
}
"""
  fragmentCode = """
#version 330 core
in vec2 TexCoords;
out vec4 color;

uniform sampler2D text;
uniform vec3 textColor;

void main()
{    
    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(text, TexCoords).r);
    color = vec4(textColor, 1.0) * sampled;
}
"""
var
  VAO, VBO: GLUint
  ft: FT_Library
  fontProgram*: Shader

proc initFT*() =
  if init(ft).int != 0:
    quit "failed to load font library"
  glGenVertexArrays(1, addr VAO)
  glGenBuffers(1, addr VBO)
  glBindVertexArray(VAO)
  glBindBuffer(GL_ARRAY_BUFFER, VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 6 * 4, nil, GL_DYNAMIC_DRAW)
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0, 4, cGL_FLOAT, GL_FALSE.GLboolean, 4 * sizeof(
      GLfloat), cast[pointer](0))
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  glBindVertexArray(0)

  fontProgram = newShader(vertexCode, fragmentCode)

proc deinitFT*() =
  discard FT_Done_FreeType(ft)

proc newFont*(face: string, size: int): Font =
  if FT_New_Face(ft, face, 0, result.face).int != 0:
    quit "failed to load font"
  discard FT_Set_Pixel_Sizes(result.face, 0, size.cuint)
  glPixelStorei(GL_UNPACK_ALIGNMENT, 1)

  for c in 0..<128:
    if FT_Load_Char(result.face, c.culong, FT_LOAD_RENDER).int != 0:
      echo "failed to load glyph '" & c.char & "'"
      continue
    var texture: GLuint
    glGenTextures(1, addr texture)
    glBindTexture(GL_TEXTURE_2D, texture)
    glTexImage2D(
      GL_TEXTURE_2D,
      0,
      GL_RED.GLint,
      result.face.glyph.bitmap.width.GLSizei,
      result.face.glyph.bitmap.rows.GLSizei,
      0,
      GL_RED,
      GL_UNSIGNED_BYTE,
      result.face.glyph.bitmap.buffer
    )

    # set texture options
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    result.characters &= Character(
      id: texture,
      size: newPoint(result.face.glyph.bitmap.width.cint,
          result.face.glyph.bitmap.rows.cint),
      bearing: newPoint(result.face.glyph.bitmap_left,
          result.face.glyph.bitmap_top),
      advance: result.face.glyph.advance.x
    )
  glBindTexture(GL_TEXTURE_2D, 0)
  discard FT_Done_Face(result.face)
  result.size = size

proc draw*(font: Font, text: string, position: Point, color: Color) =
  var pos = position
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  fontProgram.use()

  glUniform3f(glGetUniformLocation(fontProgram.id, "textColor"), color.rf,
      color.gf, color.bf)
  glActiveTexture(GL_TEXTURE0)
  glBindVertexArray(VAO)
  for c in text:
    var
      ch = font.characters[c.int]
      w = ch.size.x
      h = ch.size.y
      xpos = pos.x + ch.bearing.x
      ypos = pos.y + ch.bearing.y - (ch.size.y + ch.bearing.y) + (font.size / 2).int
      vertices = [
        [xpos.GLfloat, ypos.GLfloat + h.GLfloat, 0.0.GLfloat, 1.0.GLfloat],
        [xpos.GLfloat, ypos.GLfloat, 0.0.GLfloat, 0.0.GLfloat],
        [xpos.GLfloat + w.GLfloat, ypos.GLfloat, 1.0.GLfloat, 0.0.GLfloat],
        [xpos.GLfloat, ypos.GLfloat + h.GLfloat, 0.0.GLfloat, 1.0.GLfloat],
        [xpos.GLfloat + w.GLfloat, ypos.GLfloat, 1.0.GLfloat, 0.0.GLfloat],
        [xpos.GLfloat + w.GLfloat, ypos.GLfloat + h.GLfloat, 1.0.GLfloat, 1.0.GLfloat]
      ]

    # render texture
    glBindTexture(GL_TEXTURE_2D, ch.id)

    # update VBO
    glBindBuffer(GL_ARRAY_BUFFER, VBO)
    glBufferSubData(GL_ARRAY_BUFFER, GLintptr(0), GLsizeiptr(sizeof(vertices)), addr vertices)
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    # render quad
    glDrawArrays(GL_TRIANGLES, 0, 6)
    pos.x += (ch.advance shr 6).cint

  glBindVertexArray(0)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_BLEND)

proc sizeText*(font: Font, text: string): Vector2 =
  for c in text:
    var
      ch = font.characters[c.int]
    result.x += (ch.advance shr 6).float32
  result.y = font.size.float32
