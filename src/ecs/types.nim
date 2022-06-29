import oids
import core/types/rect
import rendering/sprite
import core/events

type
  ComponentLink* = object
    event*: EventId
    p*: proc(c: Entity, data: pointer): bool
  Component* = ref object
    lids*: seq[Oid]
    parent*: Entity
    targetLinks*: seq[ComponentLink]
    dataType*: string
    dataPtr*: ComponentData
    active*: bool
  Entity* = ref object
    id*: Oid
    components*: seq[Component]
    parent*: Entity

  ComponentData* = ref object of RootObj
