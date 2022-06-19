import core/types/vector2
import core/types/rect
import ecs/types
import ecs/component
import core/templates
import sugar
import ecs/genmacros

component RectComponent:
  var
    size: Vector2
    position: Vector2

  proc construct(dest: Rect) =
    this.size = dest.size
    this.position = dest.location
