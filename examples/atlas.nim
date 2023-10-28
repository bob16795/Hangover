import hangover
import random
import sugar
import os
import re

Game:
  var
    ta: TextureAtlas

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext) =
    clearBuffer(ctx, newColor(0, 0, 0))

  proc Setup(): AppData =
    result = newAppData()
    result.size = newPoint(512, 512)
    result.name = "Minimal Hangover Template"
    result.color = newColor(255, 255, 255)

  proc Initialize(ctx: var GraphicsContext) =
    ta = newTextureAtlas()
    for f in walkFiles("content/*.png"):
        ta &= newTextureData(f, f)
    ta.pack()

  proc Update(dt: float, delayed: bool): bool =
    discard

  proc Draw(ctx: var GraphicsContext) =
    ta["content/sprites.png"].draw(newRect(0, 0, 1, 1), newRect(0, 0, 512, 512))

  proc gameClose() =
    discard
