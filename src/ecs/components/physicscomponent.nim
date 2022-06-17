import core/types/rect
import core/types/vector2
import rendering/sprite
import rectcomponent
import ecs/types
import ecs/component
import core/templates

type
  PhysicsComponentData* = ref object of ComponentData
    velocity*: Vector2

proc updatePhysicsComponent*(parent: ptr Entity, data: pointer): bool =
  var pedata = parent[PhysicsComponentData]
  var perect = parent[RectComponentData]
  perect.position += pedata.velocity

proc newPhysicsComponent*(): Component =
  Component(
    dataType: "PhysicsComponentData",
    targetLinks:
    @[
      ComponentLink(event: EVENT_UPDATE, p: updatePhysicsComponent),
    ]
  )
