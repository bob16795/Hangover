import core/types/vector2
import core/types/rect
import ecs/types
import ecs/component
import core/templates

type
  PointComponentData* = ref object of ComponentData
    position*: Vector2

proc newPointComponent*(dest: Vector2): Component =
  Component(
    dataType: "PointComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
        parent[PointComponentData] = PointComponentData()
        parent[PointComponentData].position = dest
      ),
    ]
  )
