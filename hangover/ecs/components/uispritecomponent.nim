import hangover/core/types/rect
import hangover/core/types/vector2
import hangover/core/types/texture
import hangover/core/types/color
import hangover/ui/types/uisprite
import hangover/ecs/components/rectcomponent
import hangover/ecs/types
import hangover/ecs/component
import hangover/core/templates
import hangover/ecs/genmacros

{.experimental: "codeReordering".}

component UISpriteComponent:
  var
    sprite: UISprite
    layer: range[0..500]
    color: Color

  proc eventDraw(data: void): bool =
    var rect = parent[RectComponentData]

    this.sprite.draw(newRect(rect.position, rect.size), color = this.color)

  proc construct(tex: Texture,
                 source, center: Rect,
                 scale: Vector2,
                 color = newColor(255, 255, 255)) =
     this.sprite = newUISprite(tex, source, center).scale(scale)
     this.color = color
