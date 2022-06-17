import core/types/rect
import core/types/texture
import core/types/color
import core/types/shader
import rendering/sprite
import rectcomponent
import ecs/types
import ecs/component
import core/templates

type
  SpriteComponentData* = ref object of ComponentData
    sprite*: Sprite
    layer*: range[0..500]
    color: Color

proc drawSpriteComponent(parent: ptr Entity, data: pointer): bool =
  var rect = parent[RectComponentData]
  var this = parent[SpriteComponentData]
  
  if rect != nil and this != nil:
    this.sprite.draw(newRect(rect.position, rect.size), color = this.color, layer = this.layer)

proc newSpriteComponent*(tex: Texture, source: Rect, color: Color = newColor(255, 255, 255), layer: range[0..500] = 0, shader: ptr Shader): Component =
  Component(
    dataType: "SpriteComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_DRAW, p: drawSpriteComponent),
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[SpriteComponentData] = SpriteComponentData()
        parent[SpriteComponentData].sprite = newSprite(tex, source).setShader(shader)
        parent[SpriteComponentData].color = color
        parent[SpriteComponentData].layer = layer
      ),
    ]
  )
