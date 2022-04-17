import unittest

import gin2

suite "Rectangle":
  test "rectangle class can create from 4 args":
    var rectangle = newRect(0, 0, 4, 4)
    assert rectangle.x == 0
    assert rectangle.y == 0
    assert rectangle.width == 4
    assert rectangle.height == 4

  test "rectangle class can create from 2 points":
    var location = newPoint(0, 0)
    var size = newPoint(4, 4)
    var rectangle = newRect(location, size)
    assert rectangle.x == 0
    assert rectangle.y == 0
    assert rectangle.width == 4
    assert rectangle.height == 4

  test "rectangle location funcs":
    var rectangle = newRect(0, 0, 4, 4)

    rectangle = rectangle.offset(newPoint(1, 1))

    assert rectangle.x == 1
    assert rectangle.y == 1
    assert rectangle.width == 4
    assert rectangle.height == 4

    assert rectangle.location == newPoint(1, 1)

  test "rectangle center func":
    var rectangle = newRect(1, 1, 4, 4)
    var center = rectangle.center
    
    assert center.x == 3
    assert center.y == 3

  test "rectangle size funcs":
    discard