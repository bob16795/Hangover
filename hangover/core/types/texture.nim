import opengl
import ../lib/stbi
import rect
import vector2
import color
import shader
import math
import hashes
import hangover/core/logging

type
  Texture* = object
    ## A texture object
    tex*: GLuint
    ## the opengl texture refrence
    size*: Vector2
    ## the size of the texture

var
  textureOffset*: Vector2
  ## offsets all textures

const
  vertexCode = """
layout (location = 0) in vec4 vertex;
layout (location = 1) in vec4 tintColorIn;
uniform float rotation;
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
    color = tintColor * texture(text, texCoords);
}
"""

type
  Vert = array[0..15, GLfloat]

  QueueEntry = object
    update: bool
    shader: Shader
    texture: Texture
    verts: seq[Vert]
    layer: range[0..500]

var
  textureProgram*: Shader
  ## the default program used to render textures
  queue: seq[QueueEntry]
  pqueue: seq[Hash]
  buffers: seq[GLUint]

proc hash(entry: QueueEntry): Hash =
  var h: Hash = 0
  h = h !& hash(entry.shader.id)
  h = h !& hash(entry.texture.tex)
  h = h !& hash(entry.layer)
  for v in entry.verts:
    h = h !& hash(v)

  result = !$h

proc rotated(pos: Vector2, center: Vector2, rotation: float32): Vector2 =
  var
    p = pos - center
    s = sin(rotation)
    c = cos(rotation)
  result.x = p.x * c - p.y * s + center.x
  result.y = p.x * s + p.y * c + center.y


proc rotated(v: Vert, rotation: float32): Vert {.inline.} =
  var center = newVector2((v[8] + v[10]) / 2, (v[9] + v[11]) / 2)
  var pos1 = newvector2(v[0], v[1]).rotated(center, rotation)
  var pos2 = newvector2(v[8], v[9]).rotated(center, rotation)
  var pos3 = newvector2(v[10], v[11]).rotated(center, rotation)

  result = v
  result[0] = pos1.x
  result[1] = pos1.y
  result[8] = pos2.x
  result[9] = pos2.y
  result[10] = pos3.x
  result[11] = pos3.y

template verts(ds, de: Vector2, ss, se: Vector2, c: Color, rotation: float32): untyped =
  @[
    rotated([ds.x, ds.y, ss.x, ss.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x, de.y, ss.x, ss.y, se.x, se.y], rotation),
    rotated([de.x, de.y, se.x, se.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x, de.y, ss.x, ss.y, se.x, se.y], rotation),
    rotated([de.x, ds.y, se.x, ss.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x, de.y, ss.x, ss.y, se.x, se.y], rotation),
    rotated([ds.x, ds.y, ss.x, ss.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x, de.y, ss.x, ss.y, se.x, se.y], rotation),
    rotated([de.x, de.y, se.x, se.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x, de.y, ss.x, ss.y, se.x, se.y], rotation),
    rotated([ds.x, de.y, ss.x, se.y, c.rf, c.gf, c.bf, c.af, ds.x, ds.y, de.x, de.y, ss.x, ss.y, se.x, se.y], rotation),
  ]

proc addVBO*() =
  ## adds a vbo
  buffers &= 0.GLuint
  glGenBuffers(1, addr buffers[^1])

proc setVBOS*(count: int) =
  ## set the number of vbos
  if count < len(buffers):
    glDeleteBuffers((len(buffers) - count).GLsizei, addr buffers[count])
    buffers = buffers[0..<count]
  elif count > len(buffers):
    while count > len(buffers):
      addVBO()

proc setupTexture*() =
  ## setup texture stuff
  textureProgram = newShader(vertexCode, fragmentCode)
  textureProgram.registerParam("tintColor", SPKFloat4)
  textureProgram.registerParam("projection", SPKProj4)
  textureProgram.registerParam("rotation", SPKFloat1)
  textureProgram.registerParam("layer", SPKFloat1)

proc newTextureMem*(image: pointer, imageSize: cint): Texture =
  ## creates a new texture from a pointer
  
  # create a texture
  result = Texture()

  # generate the texture
  glGenTextures(1, addr result.tex)
  glBindTexture(GL_TEXTURE_2D, result.tex)

  # set the texture wrapping/filtering options
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

  # load the texture
  var
    width, height, channels: cint
    data: pointer = stbi_load_from_memory(cast[ptr char](image), imageSize, width, height, channels, 4)
  if data == nil:
    LOG_CRITICAL("texture", "failed to load image")
    quit(2)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
      0, GL_RGBA, GL_UNSIGNED_BYTE, data)
  glGenerateMipmap(GL_TEXTURE_2D)

  # cleanup
  stbi_image_free(data)

  # set the size
  result.size = newVector2(width.float32, height.float32)
  LOG_DEBUG("texture", "Loaded texture")

proc newTexture*(image: string): Texture =
  ## creates a new texture from a file
  
  # create the textyre
  result = Texture()

  # generate the textyre
  glGenTextures(1, addr result.tex)
  glBindTexture(GL_TEXTURE_2D, result.tex)

  # set the texture wrapping/filtering options
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

  # load the texture
  var
    width, height, channels: cint
    data: pointer = stbi_load(image, width, height, channels, 4)
  if data == nil:
    LOG_CRITICAL("texture", "failed to load image")
    quit(2)
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
      0, GL_RGBA, GL_UNSIGNED_BYTE, data)
  glGenerateMipmap(GL_TEXTURE_2D)

  # cleanup
  stbi_image_free(data)
  
  # set the size
  result.size = newVector2(width.float32, height.float32)
  LOG_DEBUG("texture", "Loaded texture")

proc aabb*(a, b: Rect): bool =
  if a.x < b.x + b.width and
     a.x + a.width > b.x and
     a.y < b.y + b.height and
     a.y + a.height > b.y:
    return true

proc draw*(texture: Texture, srcRect, dstRect: Rect, shader: ptr Shader = nil,
           color = newColor(255, 255, 255, 255), rotation: float = 0, layer: range[0..500] = 0) =
  ## draws a texture
  
  # check the program
  var program = shader
  if program == nil:
    program = addr textureProgram

  # calc the dest rectangle
  var dst = dstRect.offset(-1 * textureOffset)

  # get the verts for the new rect
  var vertices = verts(dst.location, dst.location + dst.size,
      srcRect.location, srcRect.location + srcRect.size, color, rotation)

  # if the queue is empty create it
  if queue == @[]:
    queue &= QueueEntry(
      update: true,
      shader: program[],
      texture: texture,
      verts: vertices,
      layer: layer)
  
  # attempt to add to the last queue item
  elif layer == queue[^1].layer and texture == queue[^1].texture and program[].id == queue[^1].shader.id:
    queue[^1].verts &= vertices
  
  # create a new queue item
  else:
    queue &= QueueEntry(
      update: true,
      shader: program[],
      texture: texture,
      verts: vertices,
      layer: layer)

proc finishDraw*() =
  ## renders the texture queue
    
  # gets the current program to reset later
  var startProg: GLint
  glGetIntegerv(GL_CURRENT_PROGRAM, addr startProg)

  # checks what items to redraw
  if queue != @[]:
    for i in 0..<len(queue):
      if pqueue.len() > i and hash(queue[i]) == pqueue[i]: queue[i].update = false

  # set gl options
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
  
  # set texture
  glActiveTexture(GL_TEXTURE0)

  # setup vbo data
  setVBOS(len(queue))

  # redraw needed items
  for i in 0..<len(queue):
    # get the queue data
    var
      q = queue[i]
      layer: float32 = q.layer.float32
      vertices = q.verts
   
    # use the correct program
    q.shader.use()
    q.shader.setParam("layer", addr layer)
  
    # bind the queue items texture
    glBindTexture(GL_TEXTURE_2D, q.texture.tex)
    glBindBuffer(GL_ARRAY_BUFFER, buffers[i])

    # update VBO
    if q.update:
      glBufferData(GL_ARRAY_BUFFER, GLsizeiptr(len(vertices) *
          sizeof(vertices[0])),
          addr(vertices[0]), GL_STREAM_DRAW)

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

    # unbind the buffer
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    # render
    glDrawArrays(GL_TRIANGLES, 0, (len(vertices)).GLsizei)

  # unbind the texture
  glBindTexture(GL_TEXTURE_2D, 0)
  
  # reset shader
  glUseProgram(startProg.GLuint)

  # update pqueue
  pqueue = @[]
  for qe in queue:
    pqueue &= hash(qe)

  # reset queue
  queue = @[]

proc isDefined*(texture: Texture): bool =
  ## check if a texture is defined
  return texture.tex != 0
