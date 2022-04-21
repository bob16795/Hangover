import gin2
import random
import sugar
import os

const
  SPRITES = 1/6
  SIZE = 150

Game:
  var
    texture: Texture
    uiTexture: Texture
    tiles: seq[int]
    uiFont: Font
    c: float32
    snd: Sound
    sng: Song
    um: UIManager

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 255, 255))
    echo loadStatus

  proc Setup(): AppData =
    result = newAppData()
    result.name = "Oh God"

  proc Initialize() =
    setStatus("setup font")
    uiFont = newFont(getAppDir() / "content/font.ttf", 55)
    setStatus("setup textures")
    texture = newTexture(getAppDir() / "content/sprites.bmp")
    uiTexture = newTexture(getAppDir() / "content/ui.bmp")
    setStatus("setup tiles")
    tiles = newSeq[int](SIZE * SIZE)
    randomize()
    for i in 0..<(SIZE * SIZE):
      tiles[i] = rand(3)

    setStatus("setup sounds")
    snd = newSound(getAppDir() / "content/sound.wav")
    sng = newSong(getAppDir() / "content/song.wav")
    createListener(EVENT_PRESS_KEY, (data: pointer) => play(snd))
    play(sng)


    setStatus("setup ui")
    var elem: UIElement
    elem = newUIButton(uiTexture, uiFont, newUIRectangle(25, 25, -25, -25, 0, 0,
        0.5, 1), nil, "1")
    addUIElement(elem)
    elem = newUIButton(uiTexture, uiFont, newUIRectangle(25, 25, -25, -25, 0.5,
        0, 1, 1), nil, "2")
    addUIElement(elem)

  proc Update(dt: float): bool =
    return false

  proc Draw(ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0, 255))
    for x in 0..<SIZE:
      for y in 0..<SIZE:
        texture.draw(newRect(tiles[x * SIZE + y].float32 * SPRITES, 0,
            SPRITES, 1), newRect(32 * x.float32, 32 * y.float32, 32, 32))
