import core/types/vector2
import core/types/rect
import ecs/types
import ecs/component
import core/templates
import ecs/genmacros

component PointComponent:
  var
    position: Vector2

  proc construct(dest: Vector2) =
    this.position = dest
