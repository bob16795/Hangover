import core/templates
import ecs/types
import ecs/component
import core/types/font
import core/types/color
import core/types/vector2
import rectcomponent
import strutils

import ecs/genmacros

{.experimental: "codeReordering".}

component TextComponent:
  var
    text: string
    color: Color
    font: ptr Font
    scale: float32

  proc eventDraw(data: void): bool =
    var rect = parent[RectComponentData]
    
    if rect != nil and this != nil:
      var
        h: float32
        pos: Vector2
      for text in this.text.split("\n"):
        h += this.font[].size.float32 * this.scale
      pos.y = rect.position.y + (rect.size.y - h) / 2
      pos.y = max(pos.y, rect.position.y)
      for text in this.text.split("\n"):
        var
          size = this.font[].sizeText(text)
        pos.x = (rect.position + (rect.size - size) / 2).x
        this.font[].draw(text, pos.toPoint, this.color, this.scale, layer = 5)
        pos.y += this.font[].size.float32 * this.scale

  proc construct(text: string,
                 font: ptr Font,
                 color: Color,
                 scale: float32 = 1) =
    this.text = text
    this.font = font
    this.color = color
    this.scale = scale