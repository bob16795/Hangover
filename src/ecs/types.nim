import oids
import core/types/rect
import rendering/sprite
import core/events

type
  ComponentLink* = object
    event*: EventId
    p*: proc(c: ptr Entity, data: pointer): bool
  Component* = object
    lids*: seq[Oid]
    parent*: ref Entity
    targetLinks*: seq[ComponentLink]
    dataType*: string
    dataPtr*: ComponentData
    active*: bool
  Entity* = object
    id*: Oid
    components*: seq[Component]

  ComponentData* = ref object of RootObj
