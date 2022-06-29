import component
import types
import core/types/rect
import rendering/sprite
import oids

  
when defined(hangui):
  type
    EntityEntry* = object
      name*: string
      id: Oid
      components*: seq[string]
  
  var
    entityList*: seq[EntityEntry]
  
proc newEntity*(): ref Entity =
  new(result)
  result.id = genOid()
  GC_ref(result)
  when defined(hangui):
    entityList &= EntityEntry(id: result.id, name: $result.id)

when defined(hangui):
  proc setName*(e: ref Entity, name: string) =
    for ei in 0..<len(entityList):
      template le: untyped  = entityList[ei]
      if le.id == e.id:
        le.name = name
else:
  proc setName*(e: ref Entity, name: string) {.inline.} =
    discard


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
  when defined(hangui):
    for ei in 0..<len(entityList):
      template le: untyped  = entityList[ei]
      if le.id == e.id:
        le.components &= c.dataType 

proc destroy*(e: Entity) =
  for comp in e.components: e.destroy()
