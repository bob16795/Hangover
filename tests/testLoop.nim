import unittest

import hangover

import math

suite "Loop":
  test "Can Create":
    var loop = newLoop(60)

  test "Calls Update":
    var loop = newLoop(1)
    var success = false
    loop.updateProc = proc(dt: float, delayed: bool): bool =
      success = true
    loop.drawProc = proc(ctx: var GraphicsContext) =
      discard  

    var ctx = GraphicsContext()

    loop.update(ctx)
 
    assert success

  test "Calls Draw":
    var loop = newLoop(1)
    var success = false
    loop.updateProc = proc(dt: float, delayed: bool): bool =
      discard
    loop.drawProc = proc(ctx: var GraphicsContext) =
      success = true

    var ctx = GraphicsContext()

    loop.update(ctx)

    assert success
