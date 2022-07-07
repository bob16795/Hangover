import hangover/core/events
import hangover/rendering/sprite
import hangover/ecs/types

import oids
import typetraits
import sugar

#TODO: get rid of dataType & dataPtr

template `data=`*(c: var Component, data: untyped) =
  ## sets the data for a component
  c.dataType = name(data[].type)
  c.dataPtr = data

proc data*(c: Component): ComponentData =
  ## gets the data for a component
  return c.dataPtr

proc `[]`*(c: Entity, d: typedesc): d =
  ## gets the data of type for:W an entity
  template components: untyped = c.components
  for ci in 0..<len components:
    if components[ci].dataType == name(d):
      return components[ci].dataPtr.d
  return nil

proc `[]=`*(c: Entity, d: typedesc, data: ComponentData) =
  ## sets the data of type for an entitiy
  if c != nil:
    template components: untyped = c.components
    for ci in 0..<len components:
      if components[ci].dataType == name(d):
        components[ci].dataPtr = deepCopy(data)
        GC_ref(components[ci].dataPtr)
        return

proc attachMethod*(comp: Component, event: EventId, meth: proc(c: Entity, d: pointer): bool)=
  ## attaches a event to a component
  var oid: Oid
  var tmpMeth = proc(data: pointer): bool =
    var parent = comp.parent
    return meth(parent, data)
  oid = createListener(event, tmpMeth)
  comp[].lids &= oid

proc destroy*(comp: var Component) =
  ## destroys a component
  for id in comp.lids:
    detachListener(id)

proc newComponent*(): Component =
  ## creates a component
  Component()

