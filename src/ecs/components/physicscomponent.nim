import core/types/rect
import core/types/vector2
import rendering/sprite
import rectcomponent
import ecs/types
import ecs/component
import core/templates
import ecs/genmacros

component PhysicsComponent:
  var
    velocity: Vector2

  proc updateEvent(dt: float32): bool =
    var rect = parent[RectComponentData]
    rect.position += this.velocity

  proc construct() =
    discard
