import hangover/core/types/vector2
import hangover/core/types/rect
import hangover/ecs/types
import hangover/ecs/component
import hangover/core/templates
import hangover/ecs/genmacros

import sugar

component RectComponent:
  var
    size: Vector2
    position: Vector2

  proc construct(dest: Rect) =
    this.size = dest.size
    this.position = dest.location
