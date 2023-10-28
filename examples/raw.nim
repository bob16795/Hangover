import hangover
import glfw
import sugar
import random

var data = newAppData()

var ctx = initGraphics(data)

var texture = newTexture("examples/content/sprites.bmp")

randomize()

var tiles = newSeq[int](30 * 30)
for i in 0..<(30 * 30):
  tiles[i] = rand(1)

var loop = newLoop(60)

loop.updateProc =
  proc (dt: float): bool =
    glfw.pollEvents()
    if glfw.shouldClose(ctx.window):
      return true
    return false

loop.drawProc =
  proc (dt: float, ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0, 255))
    for x in 0..29:
      for y in 0..28:
        renderTexture(texture, newRect(tiles[x * 30 + y].float32 * 0.5, 0,
            0.5, 1), newRect(32 * x.float32, 32 * y.float32, 32, 32))
    finishRender(ctx)

while not loop.done:
  loop.update(ctx)

deinitGraphics(ctx)
