import unittest

import gin2

import math

suite "Vector2":
  test "vec class can create from 2":
    var vec = newVector2(0.cint, 1.cint)
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

  # test "angle":
  #   var vec = newVector2(0, 1)
  #   assert vec.angle == 0
  #   vec.angle = PI
  #   assert vec.x == -1
  #   assert vec.y == 0
