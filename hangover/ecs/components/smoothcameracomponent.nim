import hangover/ecs/component
import hangover/ecs/types
import hangover/core/templates
import hangover/core/types/vector2
import hangover/core/types/texture
import hangover/ecs/genmacros

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
