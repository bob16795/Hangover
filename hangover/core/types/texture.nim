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

type
  Texture* = ref object of RootObj
    ## A texture object
    tex*: GLuint
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
uniform float layer;
uniform mat4 projection;

out vec2 texCoords;
out vec4 tintColor;

void main()
{
    gl_Position = projection * vec4(vertex.xy, layer, 1.0);
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
uniform int contrast_override;
uniform int mode;
uniform float contrast;

const float intensity = 1.0;

void main()
{
    vec4 tex = tintColor * texture(text, texCoords);

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
    
    if (contrast_override != 0) // has contrast tex
    {
      color.rgb = mix(
        mix(vec3(0.0), vec3(1.0 + contrast), color.rgb),
        mix(vec3(0.0 + contrast), vec3(1.0), color.rgb),
        texture(contrast_tex, texCoords).r
      );
    } else {
      if (contrast < 0) {
        color.rgb = mix(vec3(0.0), vec3(1.0 + contrast), color.rgb);
      } else {
        color.rgb = mix(vec3(0.0 + contrast), vec3(1.0), color.rgb);
      }
    }
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
    of noContrast, fg, bg: discard
    of texture:
      tex*: Texture

  QueueEntry = object
    update: bool
    shader: Shader
    id: GLuint
    verts: seq[Vert]
    layer: range[0..500]
    params: seq[TextureParam]
    scissor: Rect
    mul: bool
    contrast: ContrastEntry

proc `==`*(a, b: ContrastEntry): bool =
  if a.mode == texture and b.mode == texture:
    a.tex == b.tex
  else:
    a.mode == b.mode

var
  textureProgram*: Shader
  ## the default program used to render textures
  queue: seq[QueueEntry]
  pqueue: seq[Hash]
  buffers: seq[GLUint]
  textureScissor*: Rect
  textureSize*: Vector2
  contrastDiff*: float32
  colorMode*: int

proc setColorblindMode*(mode: int) =
  colorMode = mode

proc setContrast*(c: float32) =
  contrastDiff = c

proc hash(entry: QueueEntry): Hash =
  var h: Hash = 0
  h = h !& hash(entry.shader.id)
  h = h !& hash(entry.id)
  h = h !& hash(entry.layer)
  for v in entry.verts:
    h = h !& hash(v)

  result = !$h

proc rotated(pos: Vector2, center: Vector2, rotation: float32): Vector2 =
  let
    p = pos - center
    s = sin(rotation)
    c = cos(rotation)
  result.x = p.x * c - p.y * s + center.x
  result.y = p.x * s + p.y * c + center.y


proc rotated(v: Vert, rotation: float32, rot_center: Vector2): Vert {.inline.} =
  let
    center = newVector2(
      v[8] + (v[10] - v[8]) * rot_center.x,
      v[9] + (v[11] - v[9]) * rot_center.y
    )
    pos1 = newvector2(v[0], v[1]).rotated(center, rotation)
    pos2 = newvector2(v[8], v[9]).rotated(center, rotation)
    pos3 = newvector2(v[10], v[11]).rotated(center, rotation)

  result = v
  result[0] = pos1.x
  result[1] = pos1.y
  result[8] = pos2.x
  result[9] = pos2.y
  result[10] = pos3.x
  result[11] = pos3.y

template verts(ds, de: Vector2, ss, se: Vector2, c: Color,
    rotation: float32, rot_center: Vector2): untyped =
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

proc setVBOS*(count: int) =
  ## set the number of vbos
  # if count < len(buffers):
  #   glDeleteBuffers((len(buffers) - count).GLsizei, addr buffers[count])
  #   buffers = buffers[0..<count]
  if count > len(buffers):
    while count > len(buffers):
      addVBO()

proc setupTexture*() =
  ## setup texture stuff
  textureProgram = newShader(textureVertexCode, textureFragmentCode)
  textureProgram.registerParam("tintColor", SPKFloat4)
  textureProgram.registerParam("projection", SPKProj4)
  textureProgram.registerParam("rotation", SPKFloat1)
  textureProgram.registerParam("contrast", SPKFloat1)
  textureProgram.registerParam("contrast_override", SPKInt1)
  textureProgram.registerParam("contrast_tex", SPKInt1)
  textureProgram.registerParam("layer", SPKFloat1)
  textureProgram.registerParam("mode", SPKInt1)

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
      LOG_CRITICAL("ho->texture", "failed to load image")
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

proc aabb*(a, b: Rect): bool =
  if a.x < b.x + b.width and
     a.x + a.width > b.x and
     a.y < b.y + b.height and
     a.y + a.height > b.y:
    return true

method drawVerts*(
    texture: Texture,
    vertices: seq[Vert],
    shader: Shader = nil,
    color = newColor(255, 255, 255, 255),
    rotation: float = 0,
    layer: range[0..500] = 0,
    params: seq[TextureParam] = @[],
    flip: array[2, bool] = [false, false],
    mul: bool = false,
    contrast: ContrastEntry = ContrastEntry(mode: fg),
  ) {.base.} =
  ## draws verts in a texture

  # check the program
  var program = shader
  if program == nil:
    program = textureProgram
  if texture == nil:
    return
  # if the queue is empty create it
  if queue == @[]:
    queue &= QueueEntry(
      update: true,
      shader: program,
      id: texture.tex,
      verts: vertices,
      layer: layer,
      params: params,
      scissor: textureScissor,
      mul: mul,
      contrast: contrast,
    )

  # attempt to add to the last queue item
  elif layer == queue[^1].layer and
       texture.tex == queue[^1].id and
       program[].id == queue[^1].shader.id and
       params == queue[^1].params and
       mul == queue[^1].mul and
       contrast == queue[^1].contrast and
       textureScissor == queue[^1].scissor:
    queue[^1].verts &= vertices

  # create a new queue item
  else:
    queue &= QueueEntry(
      update: true,
      shader: program,
      id: texture.tex,
      verts: vertices,
      layer: layer,
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
    layer: range[0..500] = 0,
    params: seq[TextureParam] = @[],
    flip: array[2, bool] = [false, false],
    mul: bool = false,
    rotation_center = newVector2(0.5),
    contrast: ContrastEntry = ContrastEntry(mode: fg),
  ) {.base.} =
  ## draws a texture

  # calc the dest rectangle
  var dst = dstRect.offset(-1 * textureOffset)

  if not dst.aabb(newRect(0, 0, textureSize.x, textureSize.y)):
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
    layer,
    params,
    flip,
    mul,
    contrast
  )

proc finishDraw*() =
  ## renders the texture queue
  var startProg: GLint

  withGraphics:
    # gets the current program to reset later
    glGetIntegerv(GL_CURRENT_PROGRAM, addr startProg)

    # checks what items to redraw
    #if queue != @[]:
    #  for i in 0..<len(queue):
    #    if pqueue.len() > i and hash(queue[i]) == pqueue[i]: queue[
    #        i].update = false

    # set gl options
    glEnable(GL_BLEND)

    # set texture
    glActiveTexture(GL_TEXTURE0)

    # setup vbo data
    setVBOS(len(queue))

  # redraw needed items
  for i in 0..<len(queue):
    # get the queue data
    var
      q = queue[i]

    let
      layer: float32 = q.layer.float32
      vertices = q.verts

    # use the correct program
    q.shader.use()
    q.shader.setParam("layer", addr layer)
    for param in q.params:
      q.shader.setParam(param.name, param.data)

    let contrast = case q.contrast.mode:
      of fg:
        contrastDiff
      of bg:
        -contrastDiff
      of noContrast, texture:
        0

    q.shader.setParam("mode", addr colorMode)
    q.shader.setParam("contrast", addr contrast)

    var over: GLint = 0
      
    if q.contrast.mode == texture:
      withGraphics:
        glActiveTexture(GL_TEXTURE5)
        glBindTexture(GL_TEXTURE_2D, q.contrast.tex.tex)
      over = 1
      
    q.shader.setParam("contrast_override", addr over)

    withGraphics:
      glUseProgram(q.shader.id)
      if q.scissor.size.x == 0 or q.scissor.size.y == 0:
        glDisable(GL_SCISSOR_TEST)
      else:
        glEnable(GL_SCISSOR_TEST)

        glScissor(q.scissor.location.x.GLint,
            textureSize.y.GLint - (q.scissor.location.y.GLint +
                q.scissor.size.y.GLint),
            q.scissor.size.x.GLint,
            q.scissor.size.y.GLint)

      if q.mul:
        glBlendFunc(GL_DST_COLOR, GL_ZERO)
        # glBlendFunc(GL_ZERO, GL_SRC_COLOR)
      else:
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

      # bind the queue items texture
      glBindTexture(GL_TEXTURE_2D, q.id)
      glBindBuffer(GL_ARRAY_BUFFER, buffers[i])

      # update VBO
      if q.update:
        glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(len(vertices) *
            sizeof(vertices[0])),
            addr(vertices[0]), GL_DYNAMIC_DRAW)

      # setup vertex attrib data
      glVertexAttribPointer(0, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(
          GLfloat), cast[pointer](0))
      glEnableVertexAttribArray(0)
      glVertexAttribPointer(1, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(
          GLfloat), cast[pointer](4 * sizeof(GLfloat)))
      glEnableVertexAttribArray(1)
      glVertexAttribPointer(2, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(
          GLfloat), cast[pointer](8 * sizeof(GLfloat)))
      glEnableVertexAttribArray(2)
      glVertexAttribPointer(3, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(
          GLfloat), cast[pointer](12 * sizeof(GLfloat)))
      glEnableVertexAttribArray(3)

      # render
      glDrawArrays(GL_TRIANGLES, 0, (len(vertices)).GLsizei)

      # unbind the buffer
      glBindBuffer(GL_ARRAY_BUFFER, 0)


  withGraphics:
    # unbind the texture
    glBindTexture(GL_TEXTURE_2D, 0)

    # reset shader
    glUseProgram(startProg.GLuint)

    # update pqueue
    #pqueue = @[]
    #for qe in queue:
    #  pqueue &= hash(qe)

    # reset queue
    queue = @[]
    textureScissor = Rect()
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

proc isDefined*(texture: Texture): bool =
  ## check if a texture is defined
  return texture.tex != 0

proc bindTo*(t: Texture, to: GLenum) =
  withGraphics:
    glActiveTexture(to)
    glBindTexture(GL_TEXTURE_2D, t.tex)

    glActiveTexture(GL_TEXTURE0)
