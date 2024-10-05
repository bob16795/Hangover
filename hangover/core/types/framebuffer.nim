import opengl
import texture
import vector2
import hangover/core/logging
import hangover/core/loop

type
  FramebufferAttachment* = ref object of Texture
    target: GLenum

  Framebuffer* = ref object of RootObj
    attachments: seq[FramebufferAttachment]
    fbo: GLuint

    size*: Vector2

proc newFramebufferAttachment*(target: GLenum, size: Vector2, internal: GLenum): FramebufferAttachment =
  withGrapics:
    result = FramebufferAttachment()
    glGenTextures(1, addr result.tex)
    glBindTexture(GL_TEXTURE_2D, result.tex)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

proc freeFramebufferAttachment*(f: FramebufferAttachment) =
  withGraphics:
    glDeleteTextures(1, addr f.tex)

proc newFramebuffer*(attachments: seq[FramebufferAttachment]): Framebuffer =
  withGraphics:
    result = Framebuffer()

    glGenFramebuffers(1, addr result.fbo)

    glBindFramebuffer(GL_FRAMEBUFFER, result.fbo)

    if glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE:
      LOG_CRITICAL("ho->texture", "failed to create fbo")
      quit(2)

    result.attachments = attachments

    for a in result.attachments:
      glFramebufferTexture2D(GL_FRAMEBUFFER, a.target, GL_TEXTURE_2D, a.tex, 0)

proc freeFramebuffer*(f: Framebuffer) =
  withGraphics:
    glDeleteFramebuffers(1, addr f.fbo)

  for a in f.attachments:
    freeFramebufferAttachment(a)
