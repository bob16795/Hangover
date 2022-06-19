import core/types/rect
import core/types/vector2
import core/types/texture
import core/types/color
import ui/types/uisprite
import rectcomponent
import ecs/types
import ecs/component
import core/templates
import ecs/genmacros

{.experimental: "codeReordering".}

component UISpriteComponent:
  var
    sprite: UISprite
    layer: range[0..500]
    color: Color

  proc eventDraw(data: void): bool =
    var rect = parent[RectComponentData]

    this.sprite.draw(newRect(rect.position, rect.size), c = this.color)

  proc construct(tex: Texture,
                 source, center: Rect,
                 scale: Vector2,
                 color = newColor(255, 255, 255)) =
     this.sprite = newUISprite(tex, source, center).scale(scale)
     this.color = color
