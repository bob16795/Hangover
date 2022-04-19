import gin2
import random

Game:
  var
    texture: Texture
    tiles: seq[int]
    font: Font

  proc Setup(): GraphicsInitData =
    result = newGraphicsInitData()
    result.name = "Game"

  proc Initialize() =
    texture = newTexture("examples/content/sprites.bmp")
    tiles = newSeq[int](30 * 30)
    randomize()
    for i in 0..<(30 * 30):
      tiles[i] = rand(1)

    font = newFont("examples/content/font.ttf", 55)

  proc Update(dt: float): bool =
    return false

  proc Draw(dt: float, ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0, 255))
    for x in 0..29:
      for y in 0..29:
        texture.draw(newRect(tiles[x * 30 + y].float32 * 0.5, 0,
            0.5, 1), newRect(32 * x.float32, 32 * y.float32, 32, 32))
    font.draw("This is sample text", newPoint(30, 30), newColor(0,
        0, 0))
