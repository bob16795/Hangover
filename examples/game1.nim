import gin2
import random
import sugar

const
  SPRITES = 1/6

Game:
  var
    texture: Texture
    uiTexture: Texture
    tiles: seq[int]
    font: Font
    c: float32
    snd: Sound
    sng: Song
    um: UIManager

  proc Setup(): AppData =
    result = newAppData()
    result.name = "Oh God"

  proc Initialize() =
    texture = newTexture("examples/content/sprites.bmp")
    uiTexture = newTexture("examples/content/ui.bmp")
    tiles = newSeq[int](30 * 30)
    randomize()
    for i in 0..<(30 * 30):
      tiles[i] = rand(3)

    font = newFont("examples/content/font.ttf", 55)
    snd = newSound("examples/content/sound.wav")
    sng = newSong("examples/content/song.wav")
    createListener(EVENT_PRESS_KEY, (data: pointer) => play(snd))
    play(sng)

    var elem: UIElement
    elem = newUIButton(uiTexture, newUIRectangle(25, 25, -25, -25, 0, 0, 0.5,
        1), nil, "1")
    addUIElement(elem)
    elem = newUIButton(uiTexture, newUIRectangle(25, 25, -25, -25, 0.5, 0, 1,
        1), nil, "2")
    addUIElement(elem)

  proc Update(dt: float): bool =
    return false

  proc Draw(ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0, 255))
    for x in 0..29:
      for y in 0..29:
        texture.draw(newRect(tiles[x * 30 + y].float32 * SPRITES, 0,
            SPRITES, 1), newRect(32 * x.float32, 32 * y.float32, 32, 32))
