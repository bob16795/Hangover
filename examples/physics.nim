import hangover
import random
import sugar
import os

newCollisionLayer(LAYER_WALL)
newCollisionLayer(LAYER_PLAYER)

Game:
  var
    cm: CollisionManager
    pRect: CollisionRect
    walls: seq[CollisionRect]
    texture: Texture

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0))

  proc Setup(): AppData =
    result = newAppData()
    result.size = newPoint(200, 216)
    result.name = "Minimal Hangover Template"

  proc Initialize(ctx: var GraphicsContext) =
    walls &= newCollisionRect(0, 200, 200, 1, false)
    walls &= newCollisionRect(200, 0, 10, 200, false)
    walls &= newCollisionRect(0, -1, 200, 1, false)
    walls &= newCollisionRect(-1, 0, 1, 200, false)

    pRect = newCollisionRect(50, 50, 100, 100, true)
    pRect.velocity = newVector2(200, 200)
    pRect.elasticity = 1.0

    # setup collision manager
    cm.setCollides(LAYER_WALL, {LAYER_PLAYER})
    cm.setCollides(LAYER_PLAYER, {LAYER_WALL})

    cm.register(pRect, LAYER_PLAYER)
    cm.register(walls, LAYER_WALL)

    texture = newTexture(getAppDir() / "content/sprites.bmp")
  
  var
    fps: int
    time: float32
  
  proc Update(dt: float, delayed: bool): bool =
    time += dt
    fps += 1
    if time > 1:
      echo fps
      fps = 0
      time = 0
    cm.update(dt)

  proc Draw(ctx: var GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0))
    texture.draw(newRect(0, 0, 1, 1), pRect[])

  proc gameClose() =
    discard
