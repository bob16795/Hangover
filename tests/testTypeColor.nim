import unittest

import gin2

import math

suite "Color":
  test "color class can create from 4":
    var color = newColor(0, 0, 0, 0)
    assert color.r == 0
    assert color.g == 0
    assert color.b == 0
    assert color.a == 0
    
  test "color class can create from 3":
    var color = newColor(0, 0, 0)
    assert color.r == 0
    assert color.g == 0
    assert color.b == 0
    assert color.a == 255
    