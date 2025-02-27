import types/appdata
import types/texture
import types/vector2
import types/shader
import types/point
import types/color
import types/rect
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
import loop
import locks
import lists
import hangover/rendering/shapes
export opengl

createEvent[void] eventBlitStart, {hideLogs}
createEvent[void] eventBlitEnd, {hideLogs}

createEvent[void] eventFrameEnd, {hideLogs}
createEvent[void] eventFrameStart, {hideLogs}

proc finishDraw*()

var
  cameraPos: Vector2
  cameraSize*: Vector2
  shaders: seq[Shader]

proc setCameraPos*(pos: Vector2) =
  cameraPos = pos

  var projection = ortho(cameraPos.x, cameraPos.x + cameraSize.x.float, cameraPos.y +
      cameraSize.y.float, cameraPos.y, -100, 100)
  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)
  for si in 0..<len shaders:
    shaders[si].setParam("projection", projection.caddr)

proc setCameraSize*(size: Vector2) =
  # update the viewport in glfm
  when not defined(hangui):
    withGraphics:
      glViewport(0, 0, GLsizei(size.x), GLsizei(size.y))

  # update camrea size var
  cameraSize = size

  # update shader matrices
  var projection = ortho(
    cameraPos.x,
    cameraPos.x + size.x,
    cameraPos.y + size.y,
    cameraPos.y,
    -100, 100
  )
  fontProgram.setParam("projection", projection.caddr)
  textureProgram.setParam("projection", projection.caddr)
  for si in 0..<len shaders:
    shaders[si].setParam("projection", projection.caddr)
  textureSize.x = size.x
  textureSize.y = size.y

proc regShader*(shader: Shader) =
  shaders &= shader

proc scaleBuffer*(scale: float32) =
  ## scales the buffer

  withGraphics:
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
  result.lock.initLock()

  # setup glfw
  when not defined(ginGLFM):
    glfw.initialize()

    var c = DefaultOpenglWindowConfig
    c.title = data.name
    c.size = (w: data.size.x.int32, h: data.size.y.int32)
    c.resizable = true
    if data.aa != 0:
      c.nMultiSamples = data.aa.int32

    result.window = newWindow(c)
    result.window.setSizeLimits(600, 400, -1, -1)
    # TODO: make part of init data

    loadExtensions()

    detachCurrentContext()

  result.color = data.color
  globalCtx = result

  # setup texture data
  setupTexture()
  setupShapeTexture()

  # setup fonts
  initFT()

  # attach resize listener
  eventResize.listen do (size: Point) -> bool: 
    ## called when window is resized
    setCameraSize(size.toVector2())

  # quick resize to fix bugs
  eventResize.send(data.size)

  withGraphics:
    # setup antialiasing
    if data.aa != 0:
      glEnable(GL_MULTISAMPLE)
    glEnable(GL_DEPTH_TEST)

when defined(hangui):
  proc libSetFb*(id: GLuint, w, h: int32) {.exportc, cdecl, dynlib.} =
    withGraphics:
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
  withGraphics:
    ## clears the buffer with color
    let rf = contrastDiff * color.rf 
    let gf = contrastDiff * color.gf 
    let bf = contrastDiff * color.bf 
    glClearColor(rf, gf, bf, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT)

proc finishRender*(ctx: GraphicsContext) =
  ## finishes a draw
  finishDraw()

  eventFrameEnd.send()
  withGraphics:
    glFlush()
    glFinish()
    when not defined(ginGLFM):
      glfw.swapBuffers(ctx.window)
  eventFrameStart.send()

  clearBuffer(ctx, ctx.color)

proc isFullscreen*(ctx: GraphicsContext): bool =
  ## returns true if fullscreen
  when not defined(ginGLFM):
    monitor(ctx.window) != NoMonitor
  else:
    false

proc setShowMouse*(ctx: var GraphicsContext, value: CursorMode) =
  withGraphics:
    when not defined(ginGLFM):
      ctx.window.cursorMode = value

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
          width: mode.size.w, height: mode.size.h,
          refreshRate: mode.refreshRate)
    else:
      ctx.window.monitor = (monitor: NoMonitor, xpos: ctx.pos.x.int32,
          ypos: ctx.pos.y.int32, width: ctx.size.x.int32,
          height: ctx.size.y.int32, refreshRate: 0.int32)

proc getBufferTexture*(t: Texture) =
  ## reads the buffer into a texture

  # finish render for accurate capture
  finishDraw()

  withGraphics:
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
    buffer = newSeq[uint8](bufferSize)

    # read to the buffer
    glReadPixels(0, 0, width, height, GL_RGB, GL_UNSIGNED_BYTE, addr buffer[0])

    # generate the texture
    glBindTexture(GL_TEXTURE_2D, t.tex)

    # set the texture from the buffer
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB.GLint, width.GLsizei, height.GLsizei,
        0, GL_RGB, GL_UNSIGNED_BYTE.GLenum, addr buffer[0])

proc setCursorPos*(pos: Vector2) =
  when not defined(ginGLFM):
    `cursorPos=`(globalCtx.window, (x: pos.x.float64, y: pos.y.float64))

proc finishDraw*() =
  eventBlitStart.send()

  ## renders the texture queue
  var startProg: GLint

  withGraphics:
    # gets the current program to reset later
    glGetIntegerv(GL_CURRENT_PROGRAM, addr startProg)

    # checks what items to redraw
    #if queue != @[]:
    #  for i in 0..<len(queue):
    #    if pqueue.len() > i and hash(queue[i]) == pqueue[i]: queue[
    #        i].update = false

    # set gl options
    glEnable(GL_BLEND)

    # set texture
    glActiveTexture(GL_TEXTURE0)

  var i = 0

  # redraw needed items
  for q in queue.mitems():
    i += 1

    if i > len(buffers):
      withGraphics:
        addVBO()

    let
      vertices = q.verts

    # use the correct program
    q.shader.use()
    for param in q.params:
      q.shader.setParam(param.name, param.data)

    let contrast = case q.contrast.mode:
      of fg, texture:
        contrastDiff
      of bg:
        -contrastDiff
      of noContrast:
        0

    q.shader.setParam("mode", addr colorMode)
    q.shader.setParam("contrast", addr contrast)

    var over: GLint = 0

    if q.contrast.mode == ContrastMode.texture:
      withGraphics:
        if q.tex.contrast.isSome():
          glActiveTexture(GL_TEXTURE5)
          glBindTexture(GL_TEXTURE_2D, q.tex.contrast.get())
          glActiveTexture(GL_TEXTURE0)
          over = 1

    q.shader.setParam("contrast_override", addr over)

    withGraphics:
      glUseProgram(q.shader.id)
      if q.scissor.width == 0 or q.scissor.height == 0:
        glDisable(GL_SCISSOR_TEST)
      else:
        glEnable(GL_SCISSOR_TEST)

        glScissor(
          q.scissor.x.GLint,
          textureSize.y.GLint - (q.scissor.y.GLint + q.scissor.height.GLint),
          q.scissor.width.GLint,
          q.scissor.height.GLint,
        )

      if q.mul:
        glBlendFunc(GL_DST_COLOR, GL_ZERO)
        # glBlendFunc(GL_ZERO, GL_SRC_COLOR)
      else:
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

      # bind the queue items texture
      glBindTexture(GL_TEXTURE_2D, q.tex.tex)
      glBindBuffer(GL_ARRAY_BUFFER, buffers[i - 1])

      # update VBO
      if q.update:
        glBufferData(
          GL_ARRAY_BUFFER,
          GLsizeiptr(len(vertices) *
          sizeof(vertices[0])),
          addr(vertices[0]),
          GL_STATIC_DRAW,
        )

      # setup vertex attrib data
      glVertexAttribPointer(0, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(GLfloat), cast[pointer](0))
      glEnableVertexAttribArray(0)
      glVertexAttribPointer(1, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(GLfloat), cast[pointer](4 * sizeof(GLfloat)))
      glEnableVertexAttribArray(1)
      glVertexAttribPointer(2, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(GLfloat), cast[pointer](8 * sizeof(GLfloat)))
      glEnableVertexAttribArray(2)
      glVertexAttribPointer(3, 4, cGL_FLOAT, GL_FALSE.GLboolean, 16 * sizeof(GLfloat), cast[pointer](12 * sizeof(GLfloat)))
      glEnableVertexAttribArray(3)

      # render
      glDrawArrays(GL_TRIANGLES, 0, (len(vertices)).GLsizei)

      # unbind the buffer
      glBindBuffer(GL_ARRAY_BUFFER, 0)


  withGraphics:
    # unbind the texture
    glBindTexture(GL_TEXTURE_2D, 0)

    # reset shader
    glUseProgram(startProg.GLuint)

    # update pqueue
    #pqueue = @[]
    #for qe in queue:
    #  pqueue &= hash(qe)

    # reset queue
    queue = initSinglyLinkedList[QueueEntry]()
    textureScissor = Rect()
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

  eventBlitEnd.send()
