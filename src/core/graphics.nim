import types/appdata
import types/texture
import types/vector2
import types/shader
import types/color
import types/font

import events
when defined(ginGLFM):
  import glfm
  export glfm
else:
  import glfw
import opengl
import glm

import math
import os

export opengl

from loop import GraphicsContext

var cameraPos: Vector2
var cameraSize: Vector2

proc resizeBuffer*(data: pointer): bool =
  ## called when window is resized
  var res = cast[ptr tuple[w, h: int32]](data)[]
  when not defined(hangui):
    glViewport(0, 0, GLsizei(res.w), GLsizei(res.h))
  cameraSize = newVector2(res.w.float32, res.h.float32)
  var projection = ortho(cameraPos.x, cameraPos.x + res.w.float, cameraPos.y + res.h.float, cameraPos.y, 501, -501)

  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)
  resizeCull(data)

proc initGraphics*(data: AppData): GraphicsContext =
  ## setup graphics
  when not defined(ginGLFM):
    loadExtensions()
    
    glfw.initialize()

    var c = DefaultOpenglWindowConfig
    c.title = data.name
    c.size = (w: data.size.x, h: data.size.y)
    c.resizable = true
    if data.aa != 0:
      c.nMultiSamples = data.aa.int32

    result.window = newWindow(c)
    glfw.swapInterval(1)
  
  echo "start"
  setupTexture()
  echo "texture init"
  initFT()

  createListener(EVENT_RESIZE, resizeBuffer)

  var res = (w: data.size.x.int32, h: data.size.y.int32)
  discard resizeBuffer(addr res)
  if data.aa != 0:
    glEnable(GL_MULTISAMPLE) 
  result.color = data.color

when defined(hangui):
  proc libSetFb*(id: GLuint, w, h: int32) {.exportc, cdecl, dynlib.} =
    var res = (w: w, h: h)
    sendEvent(EVENT_RESIZE, addr res)
    glBindFramebuffer(GL_FRAMEBUFFER, id)

proc deinitGraphics*(ctx: GraphicsContext) =
  ## closes the graphics
  when not defined(ginGLFM):
    ctx.window.destroy()
    glfw.terminate()

proc clearBuffer*(ctx: GraphicsContext, color: Color) =
  ## clears the buffer with color
  glClearColor(color.rf, color.gf, color.bf, color.af)
  glClear(GL_COLOR_BUFFER_BIT)

proc finishRender*(ctx: GraphicsContext) =
  ## finishes a draw
  finishDraw()
  glFlush()
  glFinish()
  when not defined(ginGLFM):
    glfw.swapBuffers(ctx.window)
    clearBuffer(ctx, ctx.color)

proc isFullscreen*(ctx: GraphicsContext): bool =
  ## returns true if fullscreen
  when not defined(ginGLFM):
    monitor(ctx.window) != NoMonitor
  else:
    false


proc setFullscreen*(ctx: var GraphicsContext, fs: bool) =
  when not defined(ginGLFM):
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
