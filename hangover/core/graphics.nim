import types/appdata
import types/texture
import types/vector2
import types/shader
import types/color
import types/font
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

var cameraPos: Vector2
var cameraSize: Vector2
var ctx: GraphicsContext

proc resizeBuffer*(data: pointer): bool =
  ## called when window is resized
  
  # get the event data
  var res = cast[ptr tuple[w, h: int32]](data)[]

  # update the viewport in glfm
  when not defined(hangui):
    glViewport(0, 0, GLsizei(res.w), GLsizei(res.h))

  # update camrea size var
  cameraSize = newVector2(res.w.float32, res.h.float32)

  # update shader matrices
  var projection = ortho(cameraPos.x, cameraPos.x + res.w.float, cameraPos.y + res.h.float, cameraPos.y, 501, -501)
  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)

proc scaleBuffer*(scale: float32) =
  ## scales the buffer
  
  # update the shader matrices
  var projection = scale(ortho(cameraPos.x, cameraPos.x + cameraSize.x.float, cameraPos.y + cameraSize.y.float, cameraPos.y, 501, -501), scale)
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
    glfw.swapInterval(1)
  
    loadExtensions()
    
  # setup texture data
  setupTexture()

  # setup fonts
  initFT()

  # attach resize listener
  createListener(EVENT_RESIZE, resizeBuffer)

  # quick resize to fix bugs
  var res = (w: data.size.x.int32, h: data.size.y.int32)
  discard resizeBuffer(addr res)

  # setup antialiasing
  if data.aa != 0:
    glEnable(GL_MULTISAMPLE) 

  result.color = data.color
  ctx = result

when defined(hangui):
  proc libSetFb*(id: GLuint, w, h: int32) {.exportc, cdecl, dynlib.} =
    ## set the target framebuffer
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
  ## sets the window to fullscreen.
  ## does nothing if fullscreen is already correct
  when not defined(ginGLFM):
    # check if fullscreen is correct
    if isFullscreen(ctx) == fs: return
  
    # get fullscreen modes
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

proc getBufferTexture*(): Texture =
  ## reads the buffer into a texture
  
  # finish render for accurate capture
  finishDraw()

  # setup result
  result = Texture()

  # get dims
  var
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
  glGenTextures(1, addr result.tex)
  glBindTexture(GL_TEXTURE_2D, result.tex)

  # set the texture wrapping/filtering options
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,
      GL_NEAREST.GLint)
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

  # set the texture from the buffer
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA.GLint, width.GLsizei, height.GLsizei,
      0, GL_RGBA, GL_UNSIGNED_BYTE.GLenum, addr buffer[0])
