import unittest

import gin2

import math

suite "Point":
  test "point class can create from 2":
    var point = newPoint(0.cint, 1.cint)
    assert point.x == 0
    assert point.y == 1
  
  test "multiply":
    var point = newPoint(0, 1) * 2
    assert point.x == 0
    assert point.y == 2
    point = 2 * newPoint(0, 1)
    point *= 2
    assert point.x == 0
    assert point.y == 4
  
  test "divide":
    var point = newPoint(0, 4) / 2
    assert point.x == 0
    assert point.y == 2
    point /= 2
    assert point.x == 0
    assert point.y == 1

  test "add":
    var point = newPoint(0, 1) + newPoint(0, 1)
    assert point.x == 0
    assert point.y == 2
    point += newPoint(0, 1)
    assert point.x == 0
    assert point.y == 3

  test "subtract":
    var point = newPoint(0, 1) - newPoint(0, 1)
    assert point.x == 0
    assert point.y == 0
    point -= newPoint(0, 1)
    assert point.x == 0
    assert point.y == -1

  test "distance":
    var a = newPoint(0, 0)
    var b = newPoint(0, 3)

    assert distance(a, b) == 3

  test "angle":
    var point = newPoint(0, 1)
    assert point.angle == 0
    point.angle = PI
    assert point.x == -1
    assert point.y == 0