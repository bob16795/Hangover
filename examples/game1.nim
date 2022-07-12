import hangover
import random
import sugar
import os

const
  SPRITES = 1/6
  SIZE = 100

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
    delta: float32
    tmr: float32
    fps: int
    fs: bool

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 255, 255))
    LOG_TRACE("game1", loadStatus)

  proc Setup(): AppData =
    result = newAppData()
    # result.size = newPoint(100, 100)
    result.name = "Oh God"

  proc setFs() =
    fs = not fs

  proc processKey(data: pointer) =
    var key = cast[ptr Key](data)[]
    if key == keyF11:
      setFs()

  proc Initialize(ctx: var GraphicsContext) =
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
    createListener(EVENT_PRESS_KEY, (data: pointer) => processKey(data))
    play(sng)

    setStatus("setup ui")
    var elem: UIElement
    elem = newUIButton(uiTexture, uiFont, newUIRectangle(5, 5, 45, 45, 0, 0,
        0, 0), (b: int)=>setFs(), "q")
    addUIElement(elem)
    elem = newUIText(uiFont, newUIRectangle(0, 0, 55, 55, 0, 0,
        0, 0), () => $delta, align = ALeft)
    addUIElement(elem)

  proc Update(dt: float): bool =
    tmr += dt
    if tmr > 1:
      delta = fps.float32
      fps = 0
      tmr -= 1
    return false

  proc Draw(ctx: var GraphicsContext) =
    setFullscreen(ctx, fs)
    clearBuffer(ctx, newColor(0, 0, 0, 255))
    var r = newRect(0, 0, SPRITES, 1)
    for x in 0..<SIZE:
      for y in 0..<SIZE:
        r.x = tiles[x * SIZE + y].float32 * SPRITES
        texture.draw(r, newRect(32 * x.float32, 32 * y.float32, 32, 32))
    fps += 1
