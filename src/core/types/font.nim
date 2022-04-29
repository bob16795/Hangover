import freetype/freetype
import ../lib/gl
import point
import color
import shader
import vector2
import texture
import rect

type
  Font* = object
    face: FT_Face
    size*: int
    characters: seq[Character]
  Character* = object
    id: GLuint
    size: Point
    bearing: Point
    advance: int

const
  vertexCode = """
#version 330 core
layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 tintColorIn;

uniform mat4 projection;
out vec2 texRect;
out vec4 tintColorGeo;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    texRect = vertex.zw;
    tintColorGeo = tintColorIn;
}
"""
  geoCode = """
#version 330 core
layout (lines) in;
layout (triangle_strip, max_vertices = 6) out;

in vec2 texRect[2];
in vec4 tintColorGeo[2];

out vec2 texCoords;
out vec4 tintColor;

void main() {
  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[0].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[0].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[0].gl_Position.y, gl_in[1].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[0].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[1].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[1].y);
  tintColor = tintColorGeo[0];
  EmitVertex();
  
  EndPrimitive();

  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[0].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[0].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[1].gl_Position.y, gl_in[0].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[1].y);
  tintColor = tintColorGeo[0];
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[1].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[1].y);
  tintColor = tintColorGeo[0];
  EmitVertex();
  
  EndPrimitive();
}
"""
  fragmentCode = """
#version 330 core
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

  fontProgram = newShader(vertexCode, geoCode, fragmentCode)
  fontProgram.registerParam("projection", SPKProj4)
  fontProgram.registerParam("tintColor", SPKFloat4)

proc deinitFT*() =
  discard FT_Done_FreeType(ft)

proc newFont*(face: string, size: int): Font =
  if FT_New_Face(ft, face, 0, result.face).int != 0:
    quit "failed to load font"
  result.size = size
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

proc draw*(font: Font, text: string, position: Point, color: Color) =
  var pos = position

  var srect = newRect(0, 0, 1, 1)
  for c in text:
    if not font.characters.len > c.int: continue
    var
      ch = font.characters[c.int]
      w = ch.size.x
      h = ch.size.y
      xpos = pos.x + ch.bearing.x
      ypos = pos.y + ch.bearing.y - (ch.size.y + ch.bearing.y) + (
          font.size.float32 * 0.75).int

    # render texture
    var tex = Texture(tex: ch.id)
    tex.draw(srect, newRect(xpos.float32, ypos.float32, w.float32,
        h.float32), fontProgram, color)
    pos.x += (ch.advance shr 6).cint

proc sizeText*(font: Font, text: string): Vector2 =
  for c in text:
    if not font.characters.len > c.int: continue
    var
      ch = font.characters[c.int]
    result.x += (ch.advance shr 6).float32
  result.y = font.size.float32
