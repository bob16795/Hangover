import oids
import hangover/core/types/rect
import hangover/rendering/sprite
import hangover/core/events

#TODO: comment

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
