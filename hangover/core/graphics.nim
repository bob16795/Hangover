import types/appdata
import types/texture
import types/vector2
import types/shader
import types/color
import types/font
import console
import sequtils
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
from loop import GraphicsContext
export opengl

var
  cameraPos: Vector2
  cameraSize*: Vector2
  globalCtx*: GraphicsContext
  shaders: seq[Shader]

proc setCameraSize*(w, h: int32) =
  # update the viewport in glfm
  when not defined(hangui):
    glViewport(0, 0, GLsizei(w), GLsizei(h))
    
  # update camrea size var
  cameraSize = newVector2(w.float32, h.float32)

  # update shader matrices
  var projection = ortho(cameraPos.x, cameraPos.x + w.float, cameraPos.y +
      h.float, cameraPos.y, -100, 100)
  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)
  for si in 0..<len shaders:
    shaders[si].setParam("projection", projection.caddr)
  texture.size.x = w.float32
  texture.size.y = h.float32

proc resizeBuffer*(data: pointer): bool =
  ## called when window is resized

  # get the event data
  let res = cast[ptr tuple[w, h: int32]](data)[]

  setCameraSize(res.w, res.h)

proc regShader*(shader: Shader) =
  shaders &= shader

proc scaleBuffer*(scale: float32) =
  ## scales the buffer

  # update the shader matrices
  var projection = scale(ortho(cameraPos.x, cameraPos.x + cameraSize.x.float,
      cameraPos.y + cameraSize.y.float, cameraPos.y, -100, 100), scale)
  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)

  # update viewport
  glViewport(0, 0, GLsizei(cameraSize.x), GLsizei(cameraSize.y))

proc initGraphics*(data: AppData): GraphicsContext =
  ## setup graphics

  # init graphics
  result = GraphicsContext()

  # setup glfw
  when not defined(ginGLFM):
    glfw.initialize()

    var c = DefaultOpenglWindowConfig
    c.title = data.name
    c.size = (w: data.size.x, h: data.size.y)
    c.resizable = true
    if data.aa != 0:
      c.nMultiSamples = data.aa.int32

    result.window = newWindow(c)
    result.window.setSizeLimits(600, 400, -1, -1)
    # TODO: make part of init data

    loadExtensions()

  # setup texture data
  setupTexture()

  # setup fonts
  initFT()

  # attach resize listener
  createListener(EVENT_RESIZE, resizeBuffer)

  # quick resize to fix bugs
  let res = (w: data.size.x.int32, h: data.size.y.int32)
  discard resizeBuffer(addr res)

  # setup antialiasing
  if data.aa != 0:
    glEnable(GL_MULTISAMPLE)
  glEnable(GL_DEPTH_TEST)

  result.color = data.color
  globalCtx = result

when defined(hangui):
  proc libSetFb*(id: GLuint, w, h: int32) {.exportc, cdecl, dynlib.} =
    ## set the target framebuffer
    let res = (w: w, h: h)
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
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

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

proc setShowMouse*(ctx: var GraphicsContext, value: bool) =
  when not defined(ginGLFM):
    if value:
      ctx.window.cursorMode = cmNormal
    else:
      ctx.window.cursorMode = cmDisabled


proc setFullscreen*(ctx: var GraphicsContext, fs: bool) =
  ## sets the window to fullscreen.
  ## does nothing if fullscreen is already correct
  when not defined(ginGLFM):
    # check if fullscreen is correct
    if isFullscreen(ctx) == fs: return

    # get fullscreen modes
    let mon = getPrimaryMonitor()
    if fs:
      let
        pos = ctx.window.pos()
        size = ctx.window.size()
        mode = mon.videoMode()
      ctx.pos.x = pos.x.float32
      ctx.pos.y = pos.y.float32
      ctx.size.x = size.w.float32
      ctx.size.y = size.h.float32
      ctx.window.monitor = (monitor: mon, xpos: 0.int32, ypos: 0.int32,
          width: mode.size.w, height: mode.size.h, refreshRate: mode.refreshRate)
    else:
      ctx.window.monitor = (monitor: NoMonitor, xpos: ctx.pos.x.int32,
          ypos: ctx.pos.y.int32, width: ctx.size.x.int32,
          height: ctx.size.y.int32, refreshRate: 0.int32)

proc getBufferTexture*(t: Texture) =
  ## reads the buffer into a texture

  # finish render for accurate capture
  finishDraw()

  # get dims
  let
    width = cameraSize.x.GLsizei
    height = cameraSize.y.GLsizei

  # create the buffer
  let nrChannels: GLsizei = 4
  var stride: GLsizei = nrChannels * width
  if (stride mod 4) != 0:
    stride += (4 - stride mod 4)
  let bufferSize: GLsizei = stride * height
  var buffer: seq[uint8]
  buffer = 0.uint8.repeat(bufferSize)

  # read to the buffer
  glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, addr buffer[0])

  # generate the texture
  glBindTexture(GL_TEXTURE_2D, t.tex)

  # set the texture from the buffer
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
      0, GL_RGBA, GL_UNSIGNED_BYTE.GLenum, addr buffer[0])

proc setCursorPos*(pos: Vector2) =
  when not defined(ginGLFM):
    `cursorPos=`(globalCtx.window, (x: pos.x.float64, y: pos.y.float64))
