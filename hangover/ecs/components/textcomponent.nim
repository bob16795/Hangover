import hangover/core/templates
import hangover/ecs/types
import hangover/ecs/component
import hangover/core/types/font
import hangover/core/types/color
import hangover/core/types/vector2
import hangover/ecs/components/rectcomponent
import hangover/ecs/genmacros
import strutils


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
        this.font[].draw(text, pos, this.color, this.scale, layer = 5)
        pos.y += this.font[].size.float32 * this.scale

  proc construct(text: string,
                 font: ptr Font,
                 color: Color,
                 scale: float32 = 1) =
    this.text = text
    this.font = font
    this.color = color
    this.scale = scale
