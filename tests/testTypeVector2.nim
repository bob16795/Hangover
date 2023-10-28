import unittest

import hangover

import math

suite "Vector2":
  test "vec class can create from 2 ints":
    var vec = newVector2(0.int, 1.int)
    assert vec.x == 0
    assert vec.y == 1

  test "vec class can create from 2 f32s":
    var vec = newVector2(0.float32, 1.float32)
    assert vec.x == 0
    assert vec.y == 1


  test "multiply":
    var vec = newVector2(0, 1) * 2
    assert vec.x == 0
    assert vec.y == 2
    vec = 2 * newVector2(0, 1)
    vec *= 2
    assert vec.x == 0
    assert vec.y == 4

  test "divide":
    var vec = newVector2(0, 4) / 2
    assert vec.x == 0
    assert vec.y == 2
    vec /= 2
    assert vec.x == 0
    assert vec.y == 1

  test "add":
    var vec = newVector2(0, 1) + newVector2(0, 1)
    assert vec.x == 0
    assert vec.y == 2
    vec += newVector2(0, 1)
    assert vec.x == 0
    assert vec.y == 3

  test "subtract":
    var vec = newVector2(0, 1) - newVector2(0, 1)
    assert vec.x == 0
    assert vec.y == 0
    vec -= newVector2(0, 1)
    assert vec.x == 0
    assert vec.y == -1

  test "distance":
    var a = newVector2(0, 0)
    var b = newVector2(0, 3)

    assert distance(a, b) == 3

  test "createFromPoint":
    var a: Vector2 = newPoint(0, 0).toVector2()

    assert a.x == 0
    assert a.y == 0
    
  test "convertToPoint":
    var a: Point = newVector2(0, 0).toPoint()

    assert a.x == 0
    assert a.y == 0
