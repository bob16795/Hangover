import hangover/core/types/texture
import hangover/core/types/rect
import hangover/core/types/vector2
import hangover/core/types/color
import hangover/core/types/shader
import ../lib/stbi
import sequtils
import algorithm
import opengl
import hangover/core/logging
import tables
import hangover/ui/types/uirectangle

# has to be a power of 2
const TEXTURE_ATLAS_SIZE = 512

type
  TextureAtlasData* = object
    size*: Vector2
    data*: pointer
    name*: string
    stbi: bool

  TextureAtlasEntry* = ref object of Texture
    source*: Texture
    bounds*: Rect
    ta: TextureAtlas

  TextureAtlas* = ref object
    source*: Texture
    entrys*: Table[string, TextureAtlasEntry]
    target*: seq[TextureAtlasData]

proc newTextureData*(image: string, name: string): TextureAtlasData =
  # load the texture
  var
    width, height, channels: cint
    data: pointer = stbi_load(image, width, height, channels, 4)
  result.data = data
  result.size = newVector2(width.float32, height.float32)
  result.name = name
  result.stbi = true
  if data == nil:
    LOG_CRITICAL("ho->texture", "failed to load image")
    quit(2)

proc newTextureDataMem*(image: pointer, imageSize: cint,
    name: string): TextureAtlasData =
  # load the texture
  var
    width, height, channels: cint
    data: pointer = stbi_load_from_memory(cast[ptr char](image), imageSize,
        width, height, channels, 4)
  result.data = data
  result.size = newVector2(width.float32, height.float32)
  result.name = name
  result.stbi = true
  if data == nil:
    LOG_CRITICAL("ho->texture", "failed to load image")
    quit(2)

proc newTextureAtlas*(): TextureAtlas =
  result = TextureAtlas()
  result.source = Texture()

proc add*(ta: var TextureAtlas, e: TextureAtlasData) =
  ta.target &= e

proc cmpTex(a, b: TextureAtlasData): int =
  return cmp(b.size.y, a.size.y)

proc pack*(ta: var TextureAtlas) =
  glGenTextures(1, addr ta.source.tex)
  glBindTexture(GL_TEXTURE_2D, ta.source.tex)

  ta.target.sort(cmpTex)

  var
    size: GLsizei = 32
    done = false

  while not done:
    done = true
    var
      x: float32  = 0
      y: float32  = 0
      maxh: float32 = 0
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, size, size, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)

    for tidx in 0..<len(ta.target):
      var
        targ = newRect(newVector2(0, 0), ta.target[tidx].size)

      if x + targ.width > size.float32:
          y += maxh
          x = 0
          maxh = 0
      if y + targ.height > size.float32 or targ.width > size.float32:
          size *= 2
          done = false
          break

      targ.x = x
      targ.y = y

      x += targ.width
      maxh = max(maxh, targ.height)

      glTexSubImage2D(GL_TEXTURE_2D, 0, targ.x.GLint, targ.y.GLint,
          targ.width.GLsizei, targ.height.GLsizei, GL_RGBA, GL_UNSIGNED_BYTE,
          ta.target[tidx].data)
      ta.entrys[ta.target[tidx].name] = TextureAtlasEntry(bounds: targ)

  LOG_DEBUG "ho->atlas", "Packed Atlas " & $size & "x"

  for tidx in 0..<len(ta.target):
    if ta.target[tidx].stbi:
      stbi_image_free(ta.target[tidx].data)

  for vi in ta.entrys.keys:
    ta.entrys[vi].source = ta.source

  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_LINEAR.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)
  
  glGenerateMipmap(GL_TEXTURE_2D)

proc `[]`*(ta: TextureAtlas, idx: string): TextureAtlasEntry =
  return ta.entrys[idx]

method draw*(e: TextureAtlasEntry,
           srcRect, dstRect: Rect,
           shader: ptr Shader = nil,
           color = newColor(255, 255, 255, 255),
           rotation: float = 0,
           layer: range[0..500] = 0,
           params: seq[TextureParam] = @[],
           flip: array[2, bool] = [false, false]) =
  let texSrc = newRect(e.bounds.location / TEXTURE_ATLAS_SIZE, e.bounds.size / TEXTURE_ATLAS_SIZE)
  let tmpSrcRect = newUIRectangle(0, 0, 0, 0, srcRect.x, srcRect.y,
                                  srcRect.x + srcRect.width,
                                  srcRect.y + srcRect.height)
  e.source.draw(tmpSrcRect.toRect(texSrc), dstRect, shader, color, rotation,
      layer, params, flip)
