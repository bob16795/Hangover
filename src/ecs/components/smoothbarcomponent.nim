import ecs/component
import ecs/types
import core/templates
import uirectcomponent
import math

const
  BAR_SPEED* = 0.1

type
  SmoothBarComponentData* = ref object of ComponentData
    goal: float32
    max: float32
    value: float32
    id: int
    click: float32

method setGoal*(this: SmoothBarComponentData, value: float32, instant: bool) =
  this.goal = value
  if instant:
    this.value = value

method setMax*(this: SmoothBarComponentData, value: float32) =
  this.max = value

proc updateSmoothBarComponent*(parent: ptr Entity, data: pointer): bool =
  var this = parent[SmoothBarComponentData]
  let dt = cast[ptr float32](data)[]
  var rect = parent[UIRectComponentData]

  if dt >= BAR_SPEED:
    this.value = this.goal / this.max
  else:
    let diff = this.value - (this.goal / this.max)
    this.value -= diff / BAR_SPEED * dt
  
  if this.click != 0: rect.rect.anchorXMax = clamp(this.value - (this.value mod (this.click / this.max)), 0, 1)
  else: rect.rect.anchorXMax = clamp(this.value, 0, 1)
  updateRectComponent(parent)

proc newSmoothBarComponent*(click: float32 = 0): Component = 
  Component(
    dataType: "SmoothBarComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_UPDATE, p: updateSmoothBarComponent),
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[SmoothBarComponentData] = SmoothBarComponentData()
        parent[SmoothBarComponentData].click = click
      ),
    ]
  )
