import ecs/component
import ecs/types
import core/templates
import core/types/vector2
import core/types/texture
import ecs/genmacros

component SmoothCameraComponent:
  var
    pos: Vector2
    target: Vector2
    speed: float32

  proc setCamGoal(goal: Vector2) =
    this.target = goal
  
  proc getCamPos(): Vector2 =
    return this.pos

  proc eventUpdate(dt: float32): bool =
    this.pos -= (this.pos - this.target) / this.speed * dt
    textureOffset = this.pos

  proc construct(speed: float32) = 
    this.speed = speed
