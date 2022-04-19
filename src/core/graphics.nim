import types/graphicsContext
import types/texture
import types/shader
import types/font

import os, glfw

import lib/gl

import glm

import math

import types/color

export gl

proc resizeBuffer*(win: Window, res: tuple[w, h: int32]) =
  glViewport(0, 0, GLsizei(res.w), GLsizei(res.h))

  glMatrixMode(GL_PROJECTION)

  var projection = ortho(0f, res.w.float, 0, res.h.float, -1, 1f)

  glLoadMatrixf(projection.caddr)

  glMatrixMode(GL_MODELVIEW)

  fontProgram.use()
  glUniformMatrix4fv(glGetUniformLocation(fontProgram.id, "projection"), 1,
      GL_FALSE.GLboolean, projection.caddr);



proc initGraphics*(data: GraphicsInitData): GraphicsContext =
  glfw.initialize()

  var c = DefaultOpenglWindowConfig
  c.title = data.name
  c.size = (w: data.size.x, h: data.size.y)
  c.resizable = true

  result.window = newWindow(c)

  result.window.framebufferSizeCb = resizeBuffer

  if not gladLoadGL(getProcAddress):
    quit "Error initialising OpenGL"

  setupTexture()
  initFT()


  resizeBuffer(result.window, (w: data.size.x, h: data.size.y))

proc deinitGraphics*(ctx: GraphicsContext) =
  ctx.window.destroy()
  glfw.terminate()

proc finishRender*(ctx: GraphicsContext) =
  glFlush()
  glfw.swapBuffers(ctx.window)

proc clearBuffer*(ctx: GraphicsContext, color: Color) =
  glClearColor(color.rf, color.gf, color.bf, color.af)
  glClear(GL_COLOR_BUFFER_BIT)
