import core/types/rect
import core/types/vector2
import core/types/texture
import core/types/color
import ui/types/uisprite
import rectcomponent
import ecs/types
import ecs/component
import core/templates

type
  UISpriteComponentData* = ref object of ComponentData
    sprite*: UISprite
    layer*: range[0..500]
    color*: Color

proc drawUISpriteComponent(parent: ptr Entity, data: pointer): bool =
  var rect = parent[RectComponentData]
  var sedata = parent[UISpriteComponentData]
  
  if rect != nil and sedata != nil:
    sedata.sprite.draw(newRect(rect.position, rect.size), c = sedata.color)

proc newUISpriteComponent*(tex: Texture, source, center: Rect, scale: Vector2, color = newColor(255, 255, 255)): Component =
  Component(
    dataType: "UISpriteComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_DRAW, p: drawUISpriteComponent),
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[UISpriteComponentData] = UISpriteComponentData()
        parent[UISpriteComponentData].sprite = newUISprite(tex, source, center).scale(scale)
        parent[UISpriteComponentData].color = color
      ),
    ]
  )
