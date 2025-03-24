import opengl
import ../lib/stbi
import rect
import vector2
import color
import shader
import math
import hashes
import hangover/core/logging
import hangover/core/loop
import options
import lists

type
  Texture* {.acyclic.} = ref object of RootObj
    ## A texture object
    tex*: GLuint
    ## A texture object
    contrast*: Option[GLuint]
    ## the opengl texture refrence
    size*: Vector2
    ## the size of the texture

var
  textureOffset*: Vector2
  ## offsets all textures

const
  textureVertexCode* = """
layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 tintColorIn;

uniform float rotation;
uniform mat4 projection;

out vec2 texCoords;
out vec4 tintColor;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 1.0, 1.0);
    texCoords = vertex.zw;
    tintColor = tintColorIn;
}
"""
  textureFragmentCode* = """
in vec2 texCoords;
in vec4 tintColor;

out vec4 color;

uniform sampler2D text;
uniform sampler2D contrast_tex;
uniform int mode;
uniform float contrast;

const float intensity = 1.0;

void main()
{
    vec4 tex = tintColor * texture(text, texCoords);

#if defined(debug)
    float L = (17.8824 * tex.r) + (43.5161 * tex.g) + (4.11935 * tex.b);
    float M = (3.45565 * tex.r) + (27.1554 * tex.g) + (3.86714 * tex.b);
    float S = (0.02995 * tex.r) + (0.184309 * tex.g) + (1.46709 * tex.b);
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

    if (mode > 0) {
      vec4 error;
      error.r = (0.0809444479 * l) + (-0.130504409 * m) + (0.116721066 * s);
      error.g = (-0.0102485335 * l) + (0.0540193266 * m) + (-0.113614708 * s);
      error.b = (-0.000365296938 * l) + (-0.00412161469 * m) + (0.693511405 * s);
      error.a = 1.0;
      vec4 diff = tex - error;
      vec4 correction;
      correction.r = 0.0;
      correction.g =  (diff.r * 0.7) + (diff.g * 1.0);
      correction.b =  (diff.r * 0.7) + (diff.b * 1.0);
      correction = tex + correction;
      correction.a = tex.a;

      color = correction;
    } else {
      color = tex;
    }      
#else
    color = tex;
#endif

#if defined(contrast_tex_mode)
    color.rgb = mix(
      mix(vec3(0.0), vec3(1.0 - contrast), color.rgb),
      mix(vec3(0.0 + contrast), vec3(1.0), color.rgb),
      texture(contrast_tex, texCoords).r
    );
#else
    if (contrast < 0) {
      color.rgb = mix(vec3(0.0), vec3(1.0 + contrast), color.rgb);
    } else {
      color.rgb = mix(vec3(0.0 + contrast), vec3(1.0), color.rgb);
    }
#endif 
}
"""

type
  Vert = array[0..15, GLfloat]
  TextureParam* = object
    data*: pointer
    name*: string

  ContrastMode* = enum
    noContrast 
    fg
    bg
    texture

  ContrastEntry* = object
    case mode*: ContrastMode:
    of noContrast, fg, bg, texture: discard

  QueueEntry* = object
    update*: bool
    shader*: Shader
    tex*: Texture
    verts*: seq[Vert]
    params*: seq[TextureParam]
    scissor*: Rect
    mul*: bool
    contrast*: ContrastEntry

proc `or`*(a, b: ContrastEntry): ContrastEntry =
  if a.mode == noContrast: return b
  if b.mode == texture and a.mode != bg: return b
  return a

proc `==`*(a, b: ContrastEntry): bool =
  a.mode == b.mode

var
  ## the default program used to render textures
  textureProgram* {.threadvar.}: Shader
  queue* {.threadvar.}: SinglyLinkedList[QueueEntry]
  buffers*: seq[GLUint]
  textureScissor*: Rect
  textureSize*: Vector2
  contrastDiff*: float32
  colorMode*: int

template withScissor*(bounds: Rect, body: untyped): untyped =
  let oldScissor = textureScissor
  textureScissor = bounds
  try:
    body
  finally:
    textureScissor = oldScissor

proc getScissor*(): Rect =
  textureScissor

proc setColorblindMode*(mode: int) =
  colorMode = mode

proc setContrast*(c: float32) =
  contrastDiff = c

proc hash(entry: QueueEntry): Hash =
  var h: Hash = 0
  h = h !& hash(entry.shader.id)
  h = h !& hash(entry.tex.tex)
  h = h !& hash(entry.tex.contrast)
  for v in entry.verts:
    h = h !& hash(v)

  result = !$h

func rotated(pos: Vector2, center: Vector2, rotation: float32): Vector2 {.inline.} =
  if abs(rotation) < 0.005: pos
  else:
    let
      p = pos - center
      s = sin(rotation)
      c = cos(rotation)

    center + newVector2(
      p.x * c - p.y * s,
      p.x * s + p.y * c,
    )


func rotated(v: Vert, rotation: float32, rot_center: Vector2): Vert {.inline.} =
  result = v

  if abs(rotation) > 0.005:
    let
      center = newVector2(
        v[8] + (v[10] - v[8]) * rot_center.x,
        v[9] + (v[11] - v[9]) * rot_center.y
      )
      pos1 = newvector2(v[0], v[1]).rotated(center, rotation)
      pos2 = newvector2(v[8], v[9]).rotated(center, rotation)
      pos3 = newvector2(v[10], v[11]).rotated(center, rotation)

    result[0] = pos1.x
    result[1] = pos1.y
    result[8] = pos2.x
    result[9] = pos2.y
    result[10] = pos3.x
    result[11] = pos3.y

template verts(ds, de: Vector2, ss, se: Vector2, c: Color, rotation: float32, rot_center: Vector2): untyped =
  @[
    rotated([ds.x, ds.y, ss.x, ss.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x,
        de.y, ss.x, ss.y, se.x, se.y], rotation, rot_center),
    rotated([de.x, de.y, se.x, se.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x,
        de.y, ss.x, ss.y, se.x, se.y], rotation, rot_center),
    rotated([de.x, ds.y, se.x, ss.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x,
        de.y, ss.x, ss.y, se.x, se.y], rotation, rot_center),
    rotated([ds.x, ds.y, ss.x, ss.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x,
        de.y, ss.x, ss.y, se.x, se.y], rotation, rot_center),
    rotated([de.x, de.y, se.x, se.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x,
        de.y, ss.x, ss.y, se.x, se.y], rotation, rot_center),
    rotated([ds.x, de.y, ss.x, se.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x,
        de.y, ss.x, ss.y, se.x, se.y], rotation, rot_center),
  ]

proc addVBO*() =
  ## adds a vbo
  buffers &= 0.GLuint
  glGenBuffers(1, addr buffers[^1])

proc setupTexture*() =
  ## setup texture stuff
  var program = newShader(textureVertexCode, textureFragmentCode)
  program.registerParam("tintColor", SPKFloat4)
  program.registerParam("projection", SPKProj4)
  program.registerParam("rotation", SPKFloat1)
  program.registerParam("contrast", SPKFloat1)
  program.registerParam("contrast_tex", SPKInt1)
  program.registerParam("mode", SPKInt1)

  GC_ref(program)
  textureProgram = program

  block:
    let tmp: float32 = 1.0

    textureProgram.setParam("contrast", addr tmp)

  block:
    let tmp: int = 5

    textureProgram.setParam("contrast_tex", addr tmp)

proc newTexture*(size: Vector2): Texture =
  ## creates a new texture with size

  withGraphics:
    # create a texture
    result = Texture()

    # generate the texture
    glGenTextures(1, addr result.tex)
    glBindTexture(GL_TEXTURE_2D, result.tex)

    # set the texture wrapping/filtering options
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # tex nothing
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, size.x.GLsizei, size.y.GLsizei,
        0, GL_RGBA, GL_UNSIGNED_BYTE, nil)

    # set size
    result.size = size

proc newTextureMem*(image: pointer, imageSize: cint): Texture {.stdcall.} =
  ## creates a new texture from a pointer

  withGraphics:
    # create a texture
    result = Texture()

    # generate the texture
    glGenTextures(1, addr result.tex)
    glBindTexture(GL_TEXTURE_2D, result.tex)

    # set the texture wrapping/filtering options
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
        GL_NEAREST_MIPMAP_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # load the texture
    var
      width, height, channels: cint
      data: pointer = stbi_load_from_memory(cast[ptr char](image), imageSize,
          width, height, channels, 4)
    if data == nil:
      LOG_CRITICAL("ho->texture", "failed to load image texture")
      quit(2)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
        0, GL_RGBA, GL_UNSIGNED_BYTE, data)
    glGenerateMipmap(GL_TEXTURE_2D)

    # cleanup
    stbi_image_free(data)

    # set the size
    result.size = newVector2(width.float32, height.float32)
    LOG_DEBUG("ho->texture", "Loaded texture")

proc newTexture*(image: string): Texture =
  ## creates a new texture from a file

  withGraphics:
    # create the textyre
    result = Texture()

    # generate the textyre
    glGenTextures(1, addr result.tex)
    glBindTexture(GL_TEXTURE_2D, result.tex)

    # set the texture wrapping/filtering options
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
        GL_NEAREST_MIPMAP_LINEAR.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # load the texture
    var
      width, height, channels: cint
      data: pointer = stbi_load(image, width, height, channels, 4)
    if data == nil:
      LOG_CRITICAL("ho->texture", "failed to load image " & image)
      quit(2)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
        0, GL_RGBA, GL_UNSIGNED_BYTE, data)
    glGenerateMipmap(GL_TEXTURE_2D)

    # cleanup
    stbi_image_free(data)

    # set the size
    result.size = newVector2(width.float32, height.float32)
    LOG_DEBUG("ho->texture", "Loaded texture")

proc freeTexture*(t: Texture) =
  withGraphics:
    glDeleteTextures(1, addr t.tex)

method drawVerts*(
    texture: Texture,
    vertices: seq[Vert],
    shader: Shader = nil,
    color = newColor(255, 255, 255, 255),
    rotation: float = 0,
    params: seq[TextureParam] = @[],
    flip: array[2, bool] = [false, false],
    mul: bool = false,
    contrast: ContrastEntry = ContrastEntry(mode: noContrast),
  ) {.base, gcsafe.} =
  ## draws verts in a texture

  # check the program
  var program = shader
  if program == nil:
    program = textureProgram
  if texture == nil:
    return
  # if the queue is empty create it
  if queue.tail == nil:
    queue &= QueueEntry(
      update: true,
      shader: program,
      tex: texture,
      verts: vertices,
      params: params,
      scissor: textureScissor,
      mul: mul,
      contrast: contrast,
    )
    return

  let tail = queue.tail.value

  # attempt to add to the last queue item
  if texture.tex == tail.tex.tex and
     program[].id == tail.shader.id and
     params == tail.params and
     mul == tail.mul and
     contrast == tail.contrast and
     textureScissor == tail.scissor:
    queue.tail.value.verts &= vertices

  # create a new queue item
  else:
    queue &= QueueEntry(
      update: true,
      shader: program,
      tex: texture,
      verts: vertices,
      params: params,
      scissor: textureScissor,
      mul: mul,
      contrast: contrast,
    )


method draw*(
  texture: Texture,
  srcRect, dstRect: Rect,
  shader: Shader = nil,
  color = newColor(255, 255, 255, 255),
  rotation: float = 0,
  params: seq[TextureParam] = @[],
  flip: array[2, bool] = [false, false],
  mul: bool = false,
  rotation_center = newVector2(0.5),
  contrast: ContrastEntry = ContrastEntry(mode: noContrast),
) {.base, gcsafe.} =
  ## draws a texture

  # calc the dest rectangle
  var dst = dstRect.offset(-1 * textureOffset)

  if
    dst.x < -dst.width or
    dst.y < -dst.height or
    dst.x > textureSize.x or
    dst.y > textureSize.y:
    return

  if flip[1]:
    dst.y = dst.y + dst.height
    dst.height = dst.height * - 1
  if flip[0]:
    dst.x = dst.x + dst.width
    dst.width = dst.width * - 1

  # get the verts for the new rect
  let vertices = verts(
    dst.location,
    dst.location + dst.size,
    srcRect.location,
    srcRect.location + srcRect.size,
    color,
    rotation,
    rotation_center,
  )

  texture.drawVerts(
    vertices,
    shader,
    color,
    rotation,
    params,
    flip,
    mul,
    contrast
  )


proc isDefined*(texture: Texture): bool =
  ## check if a texture is defined
  return texture.tex != 0

proc bindTo*(t: Texture, to: GLenum) =
  withGraphics:
    glActiveTexture(to)
    glBindTexture(GL_TEXTURE_2D, t.tex)

    glActiveTexture(GL_TEXTURE0)
