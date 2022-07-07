import hangover/core/types/rect
import hangover/core/types/vector2
import hangover/rendering/sprite
import hangover/ecs/components/rectcomponent
import hangover/ecs/types
import hangover/ecs/component
import hangover/core/templates
import hangover/ecs/genmacros

#TODO: comment

component PhysicsComponent:
  var
    velocity: Vector2

  proc updateEvent(dt: float32): bool =
    var rect = parent[RectComponentData]
    rect.position += this.velocity

  proc construct() =
    discard
