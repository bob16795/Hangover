import gin2
import glfw

var data = newGraphicsInitData()

var ctx = initGraphics(data)

var texture = newTexture("examples/sprites.bmp")

while true:
  # Swap buffers
  glfw.pollEvents()

  # Check if we are still running
  if glfw.shouldClose(ctx.window):
    break

  glClearColor(0.0f, 0.0f, 1.0f, 1.0f)
  glClear(GL_COLOR_BUFFER_BIT)
  glPushMatrix()
  glMatrixMode(GL_MODELVIEW)
  renderTexture(texture, newRect(0, 0, 1, 1), newRect(0, 0, 500, 500))
  glPopMatrix()
  finishRender(ctx)

deinitGraphics(ctx)
