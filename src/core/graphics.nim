import types/appdata
import types/texture
import types/shader
import types/color
import types/font

import events
import lib/gl
import glfw
import glm

import math
import os

from loop import GraphicsContext

proc resizeBuffer*(data: pointer) =
  var res = cast[ptr tuple[w, h: int32]](data)[]
  glViewport(0, 0, GLsizei(res.w), GLsizei(res.h))

  glMatrixMode(GL_PROJECTION)

  var projection = ortho(0f, res.w.float, res.h.float, 0, 1, -1f)

  glLoadMatrixf(projection.caddr)

  glMatrixMode(GL_MODELVIEW)

  fontProgram.use()
  glUniformMatrix4fv(glGetUniformLocation(fontProgram.id, "projection"), 1,
      GL_FALSE.GLboolean, projection.caddr)


proc initGraphics*(data: AppData): GraphicsContext =
  glfw.initialize()

  var c = DefaultOpenglWindowConfig
  c.title = data.name
  c.size = (w: data.size.x, h: data.size.y)
  c.resizable = true

  result.window = newWindow(c)

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  setupTexture()
  initFT()

  createListener(EVENT_RESIZE, resizeBuffer)

  var res = (w: data.size.x, h: data.size.y)
  resizeBuffer(addr res)

proc deinitGraphics*(ctx: GraphicsContext) =
  ctx.window.destroy()
  glfw.terminate()

proc finishRender*(ctx: GraphicsContext) =
  glFlush()
  glfw.swapBuffers(ctx.window)

proc clearBuffer*(ctx: GraphicsContext, color: Color) =
  glClearColor(color.rf, color.gf, color.bf, color.af)
  glClear(GL_COLOR_BUFFER_BIT)
