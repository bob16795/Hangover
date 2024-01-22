import hangover/core/types/rect
import hangover/core/types/texture
import hangover/core/types/color
import hangover/core/types/shader
import hangover/rendering/sprite
import hangover/ecs/components/rectcomponent
import hangover/ecs/types
import hangover/ecs/component
import hangover/ecs/genmacros
import hangover/core/templates

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
                 shader: Shader = nil) =
    this.sprite = newSprite(tex, source).setShader(shader)
    this.color = color
    this.layer = layer
