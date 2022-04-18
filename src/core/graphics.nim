import types/graphicsContext
import types/texture

import os, glfw

import lib/gl

import glm

import math

export gl

proc resizeBuffer*(win: Window, res: tuple[w, h: int32]) =
  glViewport(0, 0, GLsizei(res.w), GLsizei(res.h))

  glMatrixMode(GL_PROJECTION)

  var projection = ortho(0f, res.w.float, res.h.float, 0, -1, 1f)

  glLoadMatrixf(projection.caddr)

  glMatrixMode(GL_MODELVIEW)

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

  resizeBuffer(result.window, (w: data.size.x, h: data.size.y))

  setupTexture()

proc deinitGraphics*(ctx: GraphicsContext) =
  ctx.window.destroy()
  glfw.terminate()

proc finishRender*(ctx: GraphicsContext) =
  glFlush()
  glfw.swapBuffers(ctx.window)
