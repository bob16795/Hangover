import ecs/component
import ecs/types
import core/templates
import uirectcomponent
import math
import ecs/genmacros


component SmoothBarComponent:
  var
    goal: float32
    max: float32
    value: float32
    id: int
    click: float32
    speed: float32

  proc setBarGoal(value: float32, instant: bool) =
    this.goal = value
    if instant:
      this.value = value

  proc setBarMax(value: float32) =
    this.max = value

  proc eventUpdate(dt: float32): bool =
    var rect = parent[UIRectComponentData]

    if dt >= this.speed:
      this.value = this.goal / this.max
    else:
      let diff = this.value - (this.goal / this.max)
      this.value -= diff / this.speed * dt

    if this.click != 0: rect.rect.anchorXMax = clamp(this.value - (this.value mod (this.click / this.max)), 0, 1)
    else: rect.rect.anchorXMax = clamp(this.value, 0, 1)
    updateRectComponent(parent)

  proc construct(speed: float32 = 0.1, click: float32 = 0) = 
    this.click = click
    this.speed = speed
    this.max = 1
    this.goal = 0
    this.value = 0
