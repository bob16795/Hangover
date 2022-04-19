import ../lib/gl
import ../lib/stbi

import rect
import vector2

type
  Texture = object
    tex*: GLuint
    size*: Vector2
  Vertex = object
    x, y: GLfloat
    u, v: GLfloat


var
  indices*: seq[GLuint] = @[
    0.GLuint, 1, 3,
    1, 2, 3
  ]
  verts: array[0..3, Vertex]


template vertices(ds, de: Vector2, ss, se: Vector2): untyped =
  [
    Vertex(x: de.x.GLfloat, y: de.y.GLfloat, u: se.x.GLfloat, v: se.y.GLfloat),
    Vertex(x: de.x.GLfloat, y: ds.y.GLfloat, u: se.x.GLfloat, v: ss.y.GLfloat),
    Vertex(x: ds.x.GLfloat, y: ds.y.GLfloat, u: ss.x.GLfloat, v: ss.y.GLfloat),
    Vertex(x: ds.x.GLfloat, y: de.y.GLfloat, u: ss.x.GLfloat, v: se.y.GLfloat),
  ]


proc setupTexture*() =
  discard

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

proc renderTexture*(texture: Texture, srcRect, dstRect: Rect) =
  verts = vertices(dstRect.location, dstRect.location + dstRect.size,
      srcRect.location, srcRect.location + srcRect.size)

  # glUseProgram(program)
  glEnable(GL_TEXTURE_2D)
  glBindTexture(GL_TEXTURE_2D, texture.tex)

  glBegin(GL_TRIANGLES)
  for v in indices:
    var vertex = verts[v]
    glTexCoord2f(vertex.u, vertex.v)
    glVertex3f(vertex.x, vertex.y, 0.0)
  glEnd()

  glDrawElements(GL_QUADS, 4, GL_UNSIGNED_INT, nil)
  glBindTexture(GL_TEXTURE_2D, 0)
  glDisable(GL_TEXTURE_2D)
