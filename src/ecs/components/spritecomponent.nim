import core/types/rect
import core/types/texture
import core/types/color
import core/types/shader
import rendering/sprite
import rectcomponent
import ecs/types
import ecs/component
import ecs/genmacros
import core/templates

component SpriteComponent:
  var
    sprite: Sprite
    layer: range[0..500]
    color: Color
  
  proc eventDraw(data: void): bool =
    var rect = parent[RectComponentData]
    
    if rect != nil and this != nil:
      this.sprite.draw(newRect(rect.position, rect.size), color = this.color, layer = this.layer)
  
  proc construct(tex: Texture, source: Rect,
                 color: Color = newColor(255, 255, 255),
                 layer: range[0..500] = 0,
                 shader: ptr Shader = nil) =
    this.sprite = newSprite(tex, source).setShader(shader)
    this.color = color
    this.layer = layer
