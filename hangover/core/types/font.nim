import freetype/freetype
import freetype/fttypes
import opengl
import point
import color
import shader
import vector2
import texture
import rect
import hangover/core/logging
import unicode
import tables
import hangover/rendering/sprite

# TODO: comment

const FONT_TEX_SIZE = 256

type
  Font* = object
    face: FT_Face
    size*: int
    textures*: seq[Texture]
    characters: Table[Rune, Character]
    spacing: int
    border*: float32
    emojis*: Table[Rune, Sprite]
    lastRune*: Rune
  Character* = object
    tex: int
    tx: GLfloat
    ty: GLfloat
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
var
  ft: FT_Library
  fontProgram*: Shader

proc initFT*() =
  if init(ft).int != 0:
    LOG_CRITICAL("ho->font", "Font library failed to load")
    quit(2)
  LOG_DEBUG("ho->font", "Loaded font library")

  fontProgram = newShader(vertexCode, fragmentCode)
  fontProgram.registerParam("projection", SPKProj4)
  fontProgram.registerParam("tintColor", SPKFloat4)
  fontProgram.registerParam("layer", SPKFloat4)

proc deinitFT*() =
  discard FT_Done_FreeType(ft)
  LOG_DEBUG("ho->font", "Unloaded font library")

template `+`(p: pointer, off: int): pointer =
  cast[pointer](cast[ByteAddress](p) +% off * sizeof(uint8))

proc finFont*(f: Font, size: int): Font =
  result = f

  discard FT_Set_Pixel_Sizes(result.face, 0, size.cuint)

  template g: untyped = result.face.glyph

  glActiveTexture(GL_TEXTURE0)

  result.textures &= newTexture(newVector2(FONT_TEX_SIZE, FONT_TEX_SIZE))
  glBindTexture(GL_TEXTURE_2D, result.textures[^1].tex)

  glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
  glPixelStorei(GL_PACK_ALIGNMENT, 1)

  var ax = 0
  var ay = 0
  var rowHeight = 0

  for c in 0..<2560:
    if FT_Get_Char_Index(result.face, c.culong) == 0:
      continue
    if FT_Load_Char(result.face, c.culong, FT_LOAD_RENDER).int != 0:
      continue
    var
      x = ax
      y = ay
    if g.bitmap.width != 0 and g.bitmap.rows != 0:
      ax += g.bitmap.width.int + 1
      if ax >= FONT_TEX_SIZE:
        x = 0
        ax = g.bitmap.width.int + 1
        ay += rowHeight
        rowHeight = g.bitmap.rows.int + 1
      if ay + g.bitmap.rows.int + 1 >= FONT_TEX_SIZE:
        y = 0
        ay = 0

        result.textures &= newTexture(newVector2(FONT_TEX_SIZE, FONT_TEX_SIZE))
        glBindTexture(GL_TEXTURE_2D, result.textures[^1].tex)

        glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
        glPixelStorei(GL_PACK_ALIGNMENT, 1)
      rowHeight = max(rowHeight, g.bitmap.rows.int + 1)
      result.size = max(result.size, g.bitmap.rows.int)

      var tmpBuffer: seq[uint8]
      var idx: int = 0
      for x in 0..g.bitmap.width:
        for y in 0..g.bitmap.rows:
          let d = cast[ptr uint8]((addr g.bitmap.buffer[0]) + idx)[]
          when not defined(fontaa):
            if d > 128:
              tmpBuffer &= 255
            else:
              tmpBuffer &= 0
          else:
            tmpBuffer &= d
          tmpBuffer &= 0
          tmpBuffer &= 0
          tmpBuffer &= 0
          idx += 1

      glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, y.GLint, g.bitmap.width.GLsizei,
          g.bitmap.rows.GLsizei, GL_RGBA, GL_UNSIGNED_BYTE, addr tmpBuffer[0])

    result.characters[c.Rune] = Character(
      size: newPoint(result.face.glyph.bitmap.width.cint,
          result.face.glyph.bitmap.rows.cint),
      bearing: newPoint(result.face.glyph.bitmap_left,
          result.face.glyph.bitmap_top),
      advance: result.face.glyph.advance.x,
      tex: result.textures.len - 1,
      ay: result.face.glyph.advance.y,
      tx: x.float32 / FONT_TEX_SIZE.float32,
      ty: y.float32 / FONT_TEX_SIZE.float32,
      tw: g.bitmap.width.float32 / FONT_TEX_SIZE.float32,
      th: g.bitmap.rows.float32 / FONT_TEX_SIZE.float32,
    )

  result.lastRune = 65535.Rune

  discard FT_Done_Face(result.face)

  for t in result.textures:
    glBindTexture(GL_TEXTURE_2D, t.tex)
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP.GLint)
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP.GLint)
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR.GLint)
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
    
    glGenerateMipmap(GL_TEXTURE_2D)
    

proc newFontMem*(data: cstring, dataSize: int64, size: int, spacing: int = 0): Font =
  if FT_New_Memory_Face(ft, data, cast[FT_Long](dataSize), 0, result.face).int != 0:
    LOG_ERROR("ho->font", "Failed to load font")
    quit(2)
  result = finFont(result, size)
  result.spacing = spacing

  LOG_DEBUG("ho->font", "Loaded font", result.textures.len , "Textures")

proc newFont*(face: string, size: int, spacing: int = 0): Font =
  if FT_New_Face(ft, face, 0, result.face).int != 0:
    LOG_ERROR("ho->font", "Failed to load font")
    quit(2)
  result = finFont(result, size)
  result.spacing = spacing
  
  LOG_DEBUG("ho->font", "Loaded font", result.textures.len , "Textures")

proc draw*(font: Font, text: string, position: Vector2, color: Color,
           scale: float32 = 1, wrap: float32 = 0, layer: range[0..500] = 0) =
  var pos = position

  var srect = newRect(0, 0, 1, 1)
  for c in text.runes:
    if c in font.emojis:
      let
        ch = font.emojis[c.Rune]
        w = (font.size.float32 * 0.8) * scale
        h = (font.size.float32 * 0.8) * scale
        xpos = pos.x + font.size.float32 * 0.1 * scale
        ypos = pos.y + font.size.float32 * 0.2 * scale

      ch.draw(newRect(xpos.float32 - font.border, ypos.float32 - font.border, w.float32 + 2 * font.border,
          h.float32 + 2 * font.border), layer = layer)
      pos.x += font.size.float32 * scale
      pos.x += font.spacing.float32 + (2 * font.border)

      continue

    if c notin font.characters: continue
    let
      ch = font.characters[c.Rune]
      w = (ch.size.x.float32 * scale)
      h = (ch.size.y.float32 * scale)

    var
      xpos = pos.x + (ch.bearing.x).float32 * scale
      ypos = pos.y - (ch.bearing.y).float32 * scale + font.size.float32 * scale

    srect.x = ch.tx
    srect.y = ch.ty
    srect.width = ch.tw
    srect.height = ch.th

    # wrap the font if enabled
    if wrap != 0 and wrap < xpos - position.x + w:
      pos.x = position.x
      pos.y += font.size.float32 * scale
      xpos = pos.x + (ch.bearing.x).float32 * scale
      ypos = pos.y - (ch.bearing.y).float32 * scale + font.size.float32 * scale

    # render texture
    let
      tex = font.textures[ch.tex]
    tex.draw(srect, newRect(xpos.float32 - font.border, ypos.float32 - font.border, w.float32 + 2 * font.border,
        h.float32 + 2 * font.border), addr fontProgram, color, layer = layer)
    pos.x += ((ch.advance shr 6).float32 * scale)
    pos.x += font.spacing.float32 + (2 * font.border)

proc draw*(font: Font, text: string, position: Point, color: Color, scale: float32 = 1, wrap: float32 = 0, layer: range[0..500] = 0) {.deprecated.} =
  font.draw(text, position.toVector2(), color, scale, wrap, layer)

proc addEmoji*(font: var Font, sprite: Sprite): string =
  result = $font.lastRune

  font.emojis[font.lastRune] = sprite

  font.lastRune = Rune(font.lastRune.int + 1)

proc sizeText*(font: Font, text: string, scale: float32 = 1): Vector2 =
  var ypos: float32 = 0 
  for c in text.runes:
    if c in font.emojis:
      result.x += font.size.float32 * scale
      result.x += font.spacing.float32 + (2 * font.border)
      continue

    if c notin font.characters: continue
    let ch = font.characters[c.Rune]
    ypos = (ch.bearing.y).float32 * scale
    let height = ypos + ch.size.y.float32 * scale
    result.x += ((ch.advance shr 6).float32 * scale)
    result.x += font.spacing.float32 + (2 * font.border).float32
    if height > result.y:
      result.y = height
