import hangover/core/types/vector2
import hangover/core/types/rect
import hangover/ecs/types
import hangover/ecs/component
import hangover/core/templates
import hangover/ecs/genmacros

#TODO: comment

component PointComponent:
  var
    position: Vector2

  proc construct(dest: Vector2) =
    this.position = dest
