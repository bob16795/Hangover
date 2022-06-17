import core/events
import rendering/sprite
import types
import oids
import typetraits
import sugar

template `data=`*(c: var Component, data: untyped) =
  c.dataType = name(data[].type)
  c.dataPtr = data

proc data*(c: Component): ComponentData =
  return c.dataPtr

proc `[]`*(c: ptr Entity, d: typedesc): d =
  template components: untyped = c.components
  for ci in 0..<len components:
    if components[ci].dataType == name(d):
      return components[ci].dataPtr.d
  echo name(d) & ":("
  return nil

proc `[]=`*(c: ptr Entity, d: typedesc, data: ComponentData) =
  if c != nil:
    template components: untyped = c.components
    for ci in 0..<len components:
      if components[ci].dataType == name(d):
        components[ci].dataPtr = deepCopy(data)
        GC_ref(components[ci].dataPtr)
        return
  echo name(d) & ":("

#proc `.()`*(c: ptr Entity) =
#  discard

proc attachMethod*(comp: ptr Component, event: EventId, meth: proc(c: ptr Entity, d: pointer): bool)=
  var oid: Oid
  var tmpMeth = proc(data: pointer): bool =
    var parent = addr(comp.parent[])
    return meth(parent, data)
  oid = createListener(event, tmpMeth)
  comp[].lids &= oid

proc destroy(comp: Component) =
  for id in comp.lids:
    detachListener(id)

proc newComponent*(): Component =
  Component()

