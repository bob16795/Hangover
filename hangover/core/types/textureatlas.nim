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

const TEXTURE_ATLAS_SIZE = 512

type
  TextureAtlasData* = object
    size: Vector2
    data: pointer
    name: string

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
  if data == nil:
    LOG_CRITICAL("ho->texture", "failed to load image")
    quit(2)

proc newTextureDataMem*(image: pointer, imageSize: cint, name: string): TextureAtlasData =
  # load the texture
  var
    width, height, channels: cint
    data: pointer = stbi_load_from_memory(cast[ptr char](image), imageSize, width, height, channels, 4)
  result.data = data
  result.size = newVector2(width.float32, height.float32)
  result.name = name
  if data == nil:
    LOG_CRITICAL("ho->texture", "failed to load image")
    quit(2)

proc newTextureAtlas*(): TextureAtlas =
  result = TextureAtlas()
  result.source = newTexture(newVector2(TEXTURE_ATLAS_SIZE, TEXTURE_ATLAS_SIZE))

proc add*(ta: var TextureAtlas, e: TextureAtlasData) =
  ta.target &= e

proc cmpTex(a, b: TextureAtlasData): int =
  var aSize = a.size.x * a.size.y
  var bSize = b.size.x * b.size.y
  if aSize == bSize:
    return cmp(min(a.size.x, a.size.y), min(b.size.x, b.size.y))
  return cmp(aSize, bSize)

proc contains(a: array[2, float32], b: float32): bool = a[0] < b and b < a[1]

proc getScore(r: Rect, packed: Table[string, TextureAtlasEntry]): float32 =
  var totalP: float32 = r.width * 2 + r.height * 2
  var touchP: float32 = 0
  if r.x == 0:
    touchP += r.height
  var rx1 = r.x
  var rx2 = r.x + r.width
  var ry1 = r.y
  var ry2 = r.y + r.height
  if rx1 < 0 or rx2 > TEXTURE_ATLAS_SIZE or
     ry1 < 0 or ry2 > TEXTURE_ATLAS_SIZE:
       return -1
  for pe in packed.values:
    var p = pe.bounds
    if p in r:
      return -1
    var px1 = p.x
    var px2 = p.x + p.width
    var ox: float32 = 0
    if px1 in [rx1, rx2]:
      ox = px1 - rx1
    if px2 in [rx1, rx2]:
      ox = rx2 - px2
    if px1 in [rx1, rx2] and px2 in [rx1, rx2]:
      ox = rx1 - rx2
    var py1 = p.y
    var py2 = p.y + p.height
    var oy: float32 = 0
    if py1 in [ry1, ry2]:
      oy = py1 - ry1
    if px2 in [ry1, ry2]:
      oy = ry2 - py2
    if px1 in [ry1, ry2] and py2 in [ry1, ry2]:
      oy = ry1 - ry2

    if px1 == rx2:
      touchP += oy
    if px2 == rx1:
      touchP += oy

    if py1 == ry2:
      touchP += ox
    if py2 == ry1:
      touchP += ox
  
  if rx1 == 0:
    touchP += r.height
  if rx2 == TEXTURE_ATLAS_SIZE:
    touchP += r.height
  if ry1 == 0:
    touchP += r.width
  if ry2 == TEXTURE_ATLAS_SIZE:
    touchP += r.width

  return touchP / totalP

proc pack*(ta: var TextureAtlas) = 
  glBindTexture(GL_TEXTURE_2D, ta.source.tex)
  ta.target.sort(cmpTex)
  var positions: seq[Vector2]
  positions &= newVector2(0, 0)
  for tidx in 0..<len(ta.target):
    var targ = newRect(0, 0, ta.target[tidx].size)
    var score = getScore(targ.offset(positions[0]), ta.entrys)
    var best = positions[0]
    var bestIdx = 0
    for pidx in 1..<len positions:
      var tmpScore = getScore(targ.offset(positions[pidx]), ta.entrys)
      if tmpScore > score:
        best = positions[pidx]
        bestIdx = pidx
        score = tmpScore
    
    if score <= 0:
      LOG_CRITICAL("ho->textureatlas", "failed to pack atlas")
      return
      quit(2)
    targ.location = best
    positions.delete(bestIdx)
    positions &= newVector2(best.x + targ.width, best.y)
    positions &= newVector2(best.x, best.y + targ.height)
    positions &= newVector2(best.x + targ.width, best.y + targ.height)
    
    glTexSubImage2D(GL_TEXTURE_2D, 0, targ.x.GLint, targ.y.GLint, targ.width.GLsizei, targ.height.GLsizei, GL_RGBA, GL_UNSIGNED_BYTE, ta.target[tidx].data)
    ta.entrys[ta.target[tidx].name] = TextureAtlasEntry(bounds: targ)

    stbi_image_free(ta.target[tidx].data)
  for vi in ta.entrys.keys:
    ta.entrys[vi].source = ta.source

proc `[]`*(ta: TextureAtlas, idx: string): TextureAtlasEntry =
  return ta.entrys[idx]

method draw*(e: TextureAtlasEntry,
           srcRect, dstRect: Rect,
           shader: ptr Shader = nil,
           color = newColor(255, 255, 255, 255),
           rotation: float = 0,
           layer: range[0..500] = 0,
           params: seq[TextureParam] = @[]) =
  var texSrc = newRect(e.bounds.location / TEXTURE_ATLAS_SIZE, e.bounds.size / TEXTURE_ATLAS_SIZE)
  var tmpSrcRect = newUIRectangle(0, 0, 0, 0, srcRect.x, srcRect.y,
                                  srcRect.x + srcRect.width,
                                  srcRect.y + srcRect.height)
  e.source.draw(tmpSrcRect.toRect(texSrc), dstRect, shader, color, rotation, layer, params)
