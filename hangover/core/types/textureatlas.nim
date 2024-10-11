import hangover/core/types/texture
import hangover/core/types/rect
import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/shader
import ../lib/stbi
import sequtils
import algorithm
import opengl
import hangover/core/logging
import tables
import hangover/ui/types/uirectangle
import hangover/core/loop
import options

# has to be a power of 2
type
  TextureAtlasData* = object
    size*: Vector2
    data*: pointer
    name*: string
    stbi: bool

  TextureAtlasEntry* = ref object of Texture
    source*: Texture
    bounds*: Rect
    parentSize: Point

  TextureAtlas* = object
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
    name: string): TextureAtlasData {.stdcall.} =
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
  result.source = Texture()

proc add*(ta: var TextureAtlas, e: TextureAtlasData) =
  ta.target &= e

proc cmpTex(a, b: TextureAtlasData): int =
  return cmp(b.size.y, a.size.y)

proc pack*(ta: var TextureAtlas) =
  ta.source = Texture()
  ta.target.sort(cmpTex)

  withGraphics:
    glGenTextures(1, addr ta.source.tex)
    glBindTexture(GL_TEXTURE_2D, ta.source.tex)

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)
    glPixelStorei(GL_PACK_ALIGNMENT, 1)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

  var
    sizex: GLsizei = 32
    sizey: GLsizei = 32
    incx: bool = true
    done = false

  while not done:
    done = true
    var
      x: float32 = 0
      y: float32 = 0
      maxh: float32 = 0

    withGraphics:
      glBindTexture(GL_TEXTURE_2D, ta.source.tex)
      glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, sizex, sizey, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil)

    for tidx in 0..<len(ta.target):
      var
        targ = newRect(newVector2(0, 0), ta.target[tidx].size)

      if x + targ.width > sizex.float32:
        y += maxh
        x = 0
        maxh = 0
      if y + targ.height > sizey.float32 or targ.width > sizex.float32:
        if incx:
          sizex *= 2
        else:
          sizey *= 2
        incx = not incx
        done = false
        break

      targ.x = x
      targ.y = y

      x += targ.width
      maxh = max(maxh, targ.height)

      if targ.width > 0 and targ.height > 0:
        withGraphics:
          glBindTexture(GL_TEXTURE_2D, ta.source.tex)
          glTexSubImage2D(GL_TEXTURE_2D, 0, targ.x.GLint, targ.y.GLint,
              targ.width.GLsizei, targ.height.GLsizei, GL_RGBA, GL_UNSIGNED_BYTE,
              ta.target[tidx].data)
      ta.entrys[ta.target[tidx].name] = TextureAtlasEntry(bounds: targ)

  LOG_DEBUG "ho->atlas", "Packed Atlas " & $sizex & "x" & $sizey

  for tidx in 0..<len(ta.target):
    if ta.target[tidx].stbi:
      stbi_image_free(ta.target[tidx].data)

  for vi in ta.entrys.keys:
    ta.entrys[vi].parentSize = newPoint(sizex, sizey)
    ta.entrys[vi].source = TextureAtlasEntry()
    ta.entrys[vi].source[] = ta.source[]

  withGraphics:
    glBindTexture(GL_TEXTURE_2D, ta.source.tex)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4)
    glPixelStorei(GL_PACK_ALIGNMENT, 4)

proc `[]`*(ta: TextureAtlas, idx: string): TextureAtlasEntry =
  return ta.entrys[idx]

method draw*(
  e: TextureAtlasEntry,
  srcRect, dstRect: Rect,
  shader: Shader = nil,
  color = newColor(255, 255, 255, 255),
  rotation: float = 0,
  layer: range[0..500] = 0,
  params: seq[TextureParam] = @[],
  flip: array[2, bool] = [false, false],
  mul: bool = false,
  rotation_center: Vector2 = newVector2(0.5),
  contrast: ContrastEntry = ContrastEntry(mode: fg),
) =
  let texSrc = newRect(e.bounds.x / e.parentSize.x.float32,
                       e.bounds.y / e.parentSize.y.float32,
                       e.bounds.width / e.parentSize.x.float32,
                       e.bounds.height / e.parentSize.y.float32)
  var tmpSrcRect = newUIRectangle(
    0, 0, 0, 0,
    srcRect.x,
    srcRect.y,
    srcRect.x + srcRect.width,
    srcRect.y + srcRect.height,
  )

  e.source.draw(
    tmpSrcRect.toRect(texSrc),
    dstRect,
    shader,
    color,
    rotation,
    layer,
    params,
    flip,
    mul,
    rotation_center,
    contrast = contrast,
  )
