import ecs/component
import ecs/types
import core/templates
import core/types/vector2
import core/types/texture

type
  SmoothCameraComponentData* = ref object of ComponentData
    pos: Vector2
    target: Vector2
    speed: float32

method setGoal*(this: SmoothCameraComponentData, goal: Vector2) =
  this.target = goal

method getPos*(this: SmoothCameraComponentData): Vector2 =
  return this.pos

proc updateSmoothCameraComponent(parent: ptr Entity, data: pointer): bool =
  let this = parent[SmoothCameraComponentData]
  let dt = cast[ptr float32](data)[]
  this.pos -= (this.pos - this.target) / this.speed * dt
  textureOffset = this.pos

proc newSmoothCameraComponent*(speed: float32): Component = 
  Component(
    dataType: "SmoothCameraComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_UPDATE, p: updateSmoothCameraComponent),
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[SmoothCameraComponentData] = SmoothCameraComponentData()
        parent[SmoothCameraComponentData].speed = speed
      ),
    ]
  )
