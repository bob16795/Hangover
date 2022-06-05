import types/appdata
import types/texture
import types/vector2
import types/shader
import types/color
import types/font

import events
import opengl
import glfw
import glm

import math
import os

export opengl

from loop import GraphicsContext

proc resizeBuffer(data: pointer) =
  ## called when window is resized
  var res = cast[ptr tuple[w, h: int32]](data)[]
  glViewport(0, 0, GLsizei(res.w), GLsizei(res.h))
  var projection = ortho(0f, res.w.float, res.h.float, 0, 1, -1)

  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)
  resizeCull(data)


proc initGraphics*(data: AppData): GraphicsContext =
  ## setup graphics
  glfw.initialize()

  var c = DefaultOpenglWindowConfig
  c.title = data.name
  c.size = (w: data.size.x, h: data.size.y)
  c.resizable = true
  c.nMultiSamples = data.aa.int32

  result.window = newWindow(c)

  loadExtensions()

  setupTexture()
  initFT()

  createListener(EVENT_RESIZE, resizeBuffer)

  var res = (w: data.size.x.int32, h: data.size.y.int32)
  resizeBuffer(addr res)
  glfw.swapInterval(1)
  echo "init"

proc deinitGraphics*(ctx: GraphicsContext) =
  ## closes the graphics
  ctx.window.destroy()
  glfw.terminate()

proc finishRender*(ctx: GraphicsContext) =
  ## finishes a draw
  finishDraw()
  glFlush()
  glfw.swapBuffers(ctx.window)
  glFinish()

proc clearBuffer*(ctx: GraphicsContext, color: Color) =
  ## clears the buffer with color
  glClearColor(color.rf, color.gf, color.bf, color.af)
  glClear(GL_COLOR_BUFFER_BIT)

proc isFullscreen*(ctx: GraphicsContext): bool =
  ## returns true if fullscreen
  monitor(ctx.window) != NoMonitor


proc setFullscreen*(ctx: var GraphicsContext, fs: bool) =
  ## sets the window to fullscreen.
  ## does nothing if fullscreen is already correct
  if isFullscreen(ctx) == fs: return

  var mon = getPrimaryMonitor()
  if fs:
    var
      pos = ctx.window.pos()
      size = ctx.window.size()
    ctx.pos.x = pos.x.float32
    ctx.pos.y = pos.y.float32
    ctx.size.x = size.w.float32
    ctx.size.y = size.h.float32
    var mode = mon.videoMode()
    ctx.window.monitor = (monitor: mon, xpos: 0.int32, ypos: 0.int32,
        width: mode.size.w, height: mode.size.h, refreshRate: 60.int32)
  else:
    ctx.window.monitor = (monitor: NoMonitor, xpos: ctx.pos.x.int32,
        ypos: ctx.pos.y.int32, width: ctx.size.x.int32,
        height: ctx.size.y.int32, refreshRate: 0.int32)
