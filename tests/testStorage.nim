import unittest
import os
import strutils

import hangover

suite "Storage":
  test "Root path works":
    APPNAME = "TestApp"

    assert getFullFilePath("cont://") == getAppDir() / "content"
    assert getFullFilePath("res://").contains("TestApp")

  test "Bad path fails":
    expect(OSError):
      discard getFullFilePath("test://")
    expect(OSError):
      discard getFullFilePath("test")
