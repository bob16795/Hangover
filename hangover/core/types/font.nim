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
import hangover/core/loop
import options

# TODO: comment

const FONT_TEX_SIZE = 256

type
  Emoji* = object
    sprite: Sprite
    color: bool

  Font* = ref object
    size*: int
    textures*: seq[Texture]
    characters: Table[Rune, Character]
    spacing: int
    border*: float32
    emojis*: Table[Rune, Emoji]
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
uniform float contrast;
uniform int mode;

void main()
{
    float sampled = texture(text, texCoords).r;
    vec4 tex = vec4(tintColor.rgb, tintColor.a * sampled);

    float L = (17.8824 * tex.r) + (43.5161 * tex.g) + (4.11935 * tex.b);
    float M = (3.45565 * tex.r) + (27.1554 * tex.g) + (3.86714 * tex.b);
    float S = (0.0299566 * tex.r) + (0.184309 * tex.g) + (1.46709 * tex.b);

    float l, m, s;

    if (mode == 0) //Normal
    {
        l = L;
        m = M;
        s = S;
    }

    if (mode == 1) //Protanopia
    {
        l = 0.0 * L + 2.02344 * M + -2.52581 * S;
        m = 0.0 * L + 1.0 * M + 0.0 * S;
        s = 0.0 * L + 0.0 * M + 1.0 * S;
    }

    if (mode == 2) //Deuteranopia
    {
        l = 1.0 * L + 0.0 * M + 0.0 * S;
        m = 0.494207 * L + 0.0 * M + 1.24827 * S;
        s = 0.0 * L + 0.0 * M + 1.0 * S;
    }

    if (mode == 3) //Tritanopia
    {
        l = 1.0 * L + 0.0 * M + 0.0 * S;
        m = 0.0 * L + 1.0 * M + 0.0 * S;
        s = -0.395913 * L + 0.801109 * M + 0.0 * S;
    }

    if (mode == 4) //contast
    {
      if (contrast < 0) {
        color = vec4(0, 0, 0, tex.a);
      } else {
        color = vec4(1, 1, 1, tex.a);
      }

      return;
    }

    vec4 error;
    error.r = (0.0809444479 * l) + (-0.130504409 * m) + (0.116721066 * s);
    error.g = (-0.0102485335 * l) + (0.0540193266 * m) + (-0.113614708 * s);
    error.b = (-0.000365296938 * l) + (-0.00412161469 * m) + (0.693511405 * s);
    error.a = 1.0;
    vec4 diff = tex - error;
    vec4 correction;
    correction.r = 0.0;
    correction.g = (diff.r * 0.7) + (diff.g * 1.0);
    correction.b = (diff.r * 0.7) + (diff.b * 1.0);
    correction = tex + correction;
    correction.a = tex.a;

    color = correction;

    if (contrast < 0) {
      color.rgb = mix(vec3(0.0), vec3(1.0 + contrast), color.rgb);
    } else {
      color.rgb = mix(vec3(0.0 + contrast), vec3(1.0), color.rgb);
    }
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
  fontProgram.registerParam("contrast", SPKFloat1)
  fontProgram.registerParam("mode", SPKInt1)

proc deinitFT*() =
  discard FT_Done_FreeType(ft)
  LOG_DEBUG("ho->font", "Unloaded font library")

template `+`(p: pointer, off: int): pointer =
  cast[pointer](cast[ByteAddress](p) +% off * sizeof(uint8))

proc finFont*(self: var Font, size: int, face: FT_Face) =
  discard FT_Set_Pixel_Sizes(face, 0, size.cuint)

  template g: untyped = face.glyph

  self.textures &= newTexture(newVector2(FONT_TEX_SIZE, FONT_TEX_SIZE))

  withGraphics:
    glActiveTexture(GL_TEXTURE0)
    glBindTexture(GL_TEXTURE_2D, self.textures[^1].tex)

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glPixelStorei(GL_PACK_ALIGNMENT, 1)

  var ax = 0
  var ay = 0
  var rowHeight = 0

  for c in 0..<2560:
    if FT_Get_Char_Index(face, c.culong) == 0:
      continue
    if FT_Load_Char(face, c.culong, FT_LOAD_RENDER).int != 0:
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
        y += rowHeight
        rowHeight = g.bitmap.rows.int + 1
      if ay + g.bitmap.rows.int + 1 >= FONT_TEX_SIZE:
        y = 0
        ay = 0

        var tex = newTexture(newVector2(FONT_TEX_SIZE, FONT_TEX_SIZE))
        withGraphics:
          glActiveTexture(GL_TEXTURE0)
          glBindTexture(GL_TEXTURE_2D, tex.tex)
          glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
          glPixelStorei(GL_PACK_ALIGNMENT, 1)
        self.textures &= tex

      rowHeight = max(rowHeight, g.bitmap.rows.int + 1)
      self.size = max(self.size, g.bitmap.rows.int)

      withGraphics:
        glActiveTexture(GL_TEXTURE0)
        glBindTexture(GL_TEXTURE_2D, self.textures[^1].tex)
        glTexSubImage2D(GL_TEXTURE_2D, 0, x.GLint, y.GLint, g.bitmap.width.GLsizei,
            g.bitmap.rows.GLsizei, GL_RED, GL_UNSIGNED_BYTE, addr g.bitmap.buffer[0])

    self.characters[c.Rune] = Character(
      size: newPoint(face.glyph.bitmap.width.cint,
          face.glyph.bitmap.rows.cint),
      bearing: newPoint(face.glyph.bitmap_left,
          face.glyph.bitmap_top),
      advance: face.glyph.advance.x,
      tex: self.textures.len - 1,
      ay: face.glyph.advance.y,
      tx: x.float32 / FONT_TEX_SIZE.float32,
      ty: y.float32 / FONT_TEX_SIZE.float32,
      tw: g.bitmap.width.float32 / FONT_TEX_SIZE.float32,
      th: g.bitmap.rows.float32 / FONT_TEX_SIZE.float32,
    )

  self.lastRune = max(self.lastRune.int32, 2560).Rune

  discard FT_Done_Face(face)

  withGraphics:
    for t in self.textures:
      glBindTexture(GL_TEXTURE_2D, t.tex)
      # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP.GLint)
      # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP.GLint)
      # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR.GLint)
      # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

      glGenerateMipmap(GL_TEXTURE_2D)

    glPixelStorei(GL_UNPACK_ALIGNMENT, 4)
    glPixelStorei(GL_PACK_ALIGNMENT, 4)

proc newFontMem*(data: cstring, dataSize: int64, size: int, spacing: int = 0): Font =
  result = Font()

  var face: FT_Face

  if FT_New_Memory_Face(ft, data, cast[FT_Long](dataSize), 0, face).int != 0:
    LOG_ERROR("ho->font", "Failed to load font")
    quit(2)
  finFont(result, size, face)
  result.spacing = spacing

  LOG_DEBUG("ho->font", "Loaded font", result.textures.len, "Textures")

proc updateFontMem*(self: var Font, data: cstring, dataSize: int64, size: int, spacing: int = 0) =
  for t in self.textures:
    t.freeTexture()

  self.textures = @[]

  var face: FT_Face

  if FT_New_Memory_Face(ft, data, cast[FT_Long](dataSize), 0, face).int != 0:
    LOG_ERROR("ho->font", "Failed to load font")
    quit(2)
  finFont(self, size, face)
  self.spacing = spacing

  LOG_DEBUG("ho->font", "Loaded font", self.textures.len, "Textures")

proc newFont*(face: string, size: int, spacing: int = 0): Font =
  result = Font()

  var font_face: FT_Face

  if FT_New_Face(ft, face, 0, font_face).int != 0:
    LOG_ERROR("ho->font", "Failed to load font")
    quit(2)
  finFont(result, size, font_face)
  result.spacing = spacing

  LOG_DEBUG("ho->font", "Loaded font", result.textures.len, "Textures")

proc draw*(
  font: Font,
  text: string,
  position: Vector2,
  color: Color,
  scale: float32 = 1,
  wrap: float32 = 0,
  layer: range[0..500] = 0,
  contrast: ContrastEntry = ContrastEntry(mode: fg),
) =
  var pos = position

  var srect = newRect(0, 0, 1, 1)
  for c in text.runes:
    if c in font.emojis:
      let
        ch = font.emojis[c.Rune].sprite
        w = (font.size.float32 * 0.8) * scale
        h = (font.size.float32 * 0.8) * scale
        xpos = pos.x + font.size.float32 * 0.1 * scale
        ypos = pos.y + font.size.float32 * 0.2 * scale

      var clr = COLOR_WHITE

      if font.emojis[c.Rune].color:
        clr = color

      ch.draw(
        newRect(xpos.float32 - font.border, ypos.float32 - font.border, w.float32 + 2 * font.border, h.float32 + 2 * font.border),
        layer = layer,
        color = clr,
        contrast = contrast,
      )
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
    tex.draw(
      srect,
      newRect(xpos.float32 - font.border, ypos.float32 - font.border, w.float32 + 2 * font.border, h.float32 + 2 * font.border),
      fontProgram,
      color,
      layer = layer,
      contrast = contrast,
    )
    pos.x += ((ch.advance shr 6).float32 * scale)
    pos.x += font.spacing.float32 + (2 * font.border)

proc setEmoji*(font: var Font, emoji: Rune, sprite: Sprite, color: bool = false) =
  font.emojis[emoji] = Emoji(
    sprite: sprite,
    color: color,
  )

proc addEmoji*(font: var Font): Rune =
  result = font.lastRune

  font.lastRune = Rune(font.lastRune.int + 1)

proc sizeText*(font: Font, text: string, scale: float32 = 1, wrap: float32 = 0): Vector2 =
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

proc freeFont*(self: Font) =
  for t in self.textures:
    t.freeTexture()