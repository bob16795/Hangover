import component
import types
import core/types/rect
import rendering/sprite
import oids

proc newEntity*(): ref Entity =
  new(result)
  result.id = genOid()
  GC_ref(result)

proc attachComponent*(e: ref Entity, c: Component) =
  e[].components &= c
  GC_ref(e)
  var comp = addr e[].components[^1]
  comp.parent = e
  #GC_ref(comp[])
  #GC_ref(e[])
  for link in 0..<len c.targetLinks:
    comp.attachMethod(c.targetLinks[link].event, c.targetLinks[link].p)
  comp.targetLinks = @[]
  comp.active = true

proc destroy*(e: Entity) =
  for comp in e.components: e.destroy()
