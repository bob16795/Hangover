import ../lib/gl
import ../lib/stbi

import rect
import vector2
import shader

type
  Texture* = object
    tex*: GLuint
    size*: Vector2

const
  vertexCode = """
#version 330 core
in vec4 vertex;

uniform mat4 projection;
out vec2 texRect;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    texRect = vertex.zw;
}
"""
  geoCode = """
#version 330 core
layout (lines) in;
layout (triangle_strip, max_vertices = 6) out;

in vec2 texRect[2];

out vec2 texCoords;

void main() {
  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[0].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[0].y);
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[0].gl_Position.y, gl_in[1].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[0].y);
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[1].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[1].y);
  EmitVertex();
  
  EndPrimitive();

  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[0].gl_Position.y, gl_in[0].gl_Position.z, gl_in[0].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[0].y);
  EmitVertex();

  gl_Position = vec4(gl_in[0].gl_Position.x, gl_in[1].gl_Position.y, gl_in[0].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[0].x, texRect[1].y);
  EmitVertex();

  gl_Position = vec4(gl_in[1].gl_Position.x, gl_in[1].gl_Position.y, gl_in[1].gl_Position.z, gl_in[1].gl_Position.w);
  texCoords = vec2(texRect[1].x, texRect[1].y);
  EmitVertex();
  
  EndPrimitive();
}
"""
  postVertexCode = """
#version 330 core
in vec4 vertex;

uniform mat4 projection;

void post()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
}
"""
  fragmentCode = """
#version 330 core
in vec2 texCoords;

out vec4 color;

uniform sampler2D text;

void main()
{
    color = texture(text, texCoords);
}
"""
  BATCH_TEXTURES* = 2048

var
  VAO, VBO: GLUint
  textureProgram*: Shader
  queue*: seq[tuple[t: Texture, vs: seq[array[0..3, GLFloat]]]]
  cullSize*: Vector2

template verts(ds, de: Vector2, ss, se: Vector2): untyped =
  @[
    [ds.x, ds.y, ss.x, ss.y],
    [de.x, de.y, se.x, se.y],
  ]

proc resizeCull*(data: pointer) =
  var size = cast[ptr tuple[w, h: int32]](data)[]
  cullSize = newVector2(size.w, size.h)

proc setupTexture*() =
  glGenVertexArrays(1, addr VAO)
  glGenBuffers(1, addr VBO)
  glBindVertexArray(VAO)
  glBindBuffer(GL_ARRAY_BUFFER, VBO)
  glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * BATCH_TEXTURES * 2 * 4, nil, GL_DYNAMIC_DRAW)
  glEnableVertexAttribArray(0)
  glVertexAttribPointer(0, 4, cGL_FLOAT, GL_FALSE.GLboolean, 4 * sizeof(
      GLfloat), cast[pointer](0))
  glBindBuffer(GL_ARRAY_BUFFER, 0)
  textureProgram = newShader(vertexCode, geoCode, postVertexCode, fragmentCode)

proc newTexture*(image: string): Texture =
  glGenTextures(1, addr result.tex)

  glEnable(GL_TEXTURE_2D)
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
    quit "failed to load image"
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
      0, GL_RGBA, GL_UNSIGNED_BYTE.GLenum, data)
  glGenerateMipmap(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_TEXTURE_2D)
  stbi_image_free(data)

  result.size = newVector2(width, height)

proc aabb*(a, b: Rect): bool =
  if a.x < b.x + b.width and
     a.x + a.width > b.x and
     a.y < b.y + b.height and
     a.y + a.height > b.y:
    return true


proc draw*(texture: Texture, srcRect, dstRect: Rect) =
  if (not dstRect.aabb(newRect(newVector2(0, 0), cullSize))): return
  var vertices = verts(dstRect.location, dstRect.location + dstRect.size,
      srcRect.location, srcRect.location + srcRect.size)
  if queue == @[]:
    queue &= (t: texture, vs: vertices)
    return
  if texture == queue[^1].t and len(queue[^1].vs) / 2 + 1 < BATCH_TEXTURES:
    queue[^1].vs &= vertices
  else:
    queue &= (t: texture, vs: vertices)

proc finishDraw*() =
  # set texture
  glEnable(GL_BLEND)
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  textureProgram.use()

  glActiveTexture(GL_TEXTURE0)
  glBindVertexArray(VAO)
  for q in queue:
    var last = len(q.vs)
    var vertices = q.vs

    glBindTexture(GL_TEXTURE_2D, q.t.tex)

    # update VBO
    glBindBuffer(GL_ARRAY_BUFFER, VBO)
    glBufferSubData(GL_ARRAY_BUFFER, GLintptr(0), GLsizeiptr(len(vertices) *
        sizeof(vertices[0])), addr(vertices[0]))
    glBindBuffer(GL_ARRAY_BUFFER, 0)

    # render
    glDrawArrays(GL_LINES, 0, (len(vertices)).GLsizei)

  glBindVertexArray(0)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_BLEND)
  queue = @[]

proc isDefined*(texture: Texture): bool =
  return texture.tex != 0
