import hangover

GameECS "lol":
  var
    tex: Texture = newTexture("content/ui.bmp")
    e: Entity = newEntity()

  proc Setup(): AppData =
    result = newAppData()
    result.name = "Minimal Hangover Template"

  proc moveToMouse(parent: ptr Entity, data: pointer) =
    var pos = cast[ptr tuple[x, y: float64]](data)
    var dat = parent[RectComponentData]
    if dat != nil:
      dat.position = newVector2(pos.x.float32 - 50, pos.y.float32 - 50)
      dat.size = newVector2(100, 100)
  
  var c = newRectComponent(newRect(0, 0, 100, 100))
  attachComponent(addr e, c)
  c = newSpriteDrawComponent(tex, newRect(0, 0, 0.5, 1))
  attachComponent(addr e, c)
  c = newComponent()
  c.targetLinks &= ComponentLink(event: EVENT_MOUSE_MOVE, p: moveToMouse)
  attachComponent(addr e, c)
