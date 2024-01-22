import hangover
import random
import sugar
import os

Game:
  var
    bg: Color

  proc drawLoading(pc: float32, loadStatus: string, ctx: GraphicsContext, size: Point) =
    clearBuffer(ctx, bg)

  proc Setup(): AppData =
    bg = newColor(0, 0, 255)
    result = newAppData()
    result.name = "Minimal Hangover Template"

  proc Initialize(ctx: ptr GraphicsContext) {.async.} =
    discard

  proc Update(dt: float, delayed: bool): bool =
    discard

  proc Draw(ctx: var GraphicsContext) =
    clearBuffer(ctx, bg)

  proc gameClose() =
    discard
