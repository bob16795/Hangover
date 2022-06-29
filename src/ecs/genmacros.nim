import macros
import tables
import core/events
import strutils
import types
import sugar

type
  ComponentMethod = object
    name: string
    params: NimNode
    stmtList: NimNode
    hasEvent: bool
    event: string

proc `$`(comps: seq[ComponentMethod]): string =
  for c in comps:
    result &= c.name & ":\n"
    result &= "  " & c.params.repr & "\n"
    result &= "  " & $c.stmtList.kind & "\n"
    if c.hasEvent:
      result &= "  `" & c.event & "`\n"
    else:
      result &= "  NO EVENT\n"

type MultiData = object

macro components*(multiBody: untyped): untyped =
  result = nnkStmtList.newTree(
    nnkTypeSection.newTree(
    )
  )
  for section in multiBody:
    var variables: Table[string, NimNode]
    var methods: seq[ComponentMethod]
    let head = section[0]
    let body = section[1]
    let name = head.repr
    let dataName = name & "Data"
    let newName = "new" & name[0].toUpperAscii & name[1..^1]
    for bodyNode in body:
      case bodyNode.kind:
        of nnkVarSection:
          for node in bodyNode:
            variables[node[0].strVal] = node[1]
        of nnkProcDef:
          var tmpMethod: ComponentMethod
          tmpMethod.name = bodyNode[0].strVal
          tmpMethod.params = bodyNode[3]
          tmpMethod.stmtList = bodyNode[^1]
          tmpMethod.hasEvent = tmpMethod.name.startsWith("event")
          if tmpMethod.hasEvent:
            var eventName = ""
            for c in tmpMethod.name:
              if c.isUpperAscii:
                eventName &= "_"
              eventName &= c.toUpperAscii
            tmpMethod.event = eventName
            tmpMethod.name &= name
          methods &= tmpMethod
        else:
          quit("invalid node kind: " & $bodyNode.kind)
    var typeSection = nnkTypeDef.newTree(
      nnkPostFix.newTree(
        newIdentNode("*"),
        newIdentNode(dataName)
      ),
      newEmptyNode(),
      nnkRefTy.newTree(
        nnkObjectTy.newTree(
          newEmptyNode(),
          nnkOfInherit.newTree(
            newIdentNode("ComponentData")
          ),
          nnkRecList.newTree(
            # filled in next for loop
          )
        )
      )
    )
    for v in variables.keys:
      typeSection[2][0][2] &= nnkIdentDefs.newTree(
        nnkPostfix.newTree(
          newIdentNode("*"),
          newIdentNode(v),
        ),
        variables[v],
        newEmptyNode()
      )
    result[0] &= typeSection
    for m in methods:
      var procSection = nnkProcDef.newTree(
        nnkPostfix.newTree(
          newIdentNode("*"),
          newIdentNode(m.name),
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          m.params[0],
          nnkIdentDefs.newTree(
            newIdentNode("parent"),
            nnkPtrTy.newTree(
              newIdentNode("Entity")
            ),
            newEmptyNode()
          )
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
          nnkVarSection.newTree(
            nnkIdentDefs.newTree(
              newIdentNode("this"),
              newEmptyNode(),
              nnkCall.newTree(
                newIdentNode("[]"),
                newIdentNode("parent"),
                newIdentNode(dataName)
              )
            )
          ) 
        )
      )
      if m.name == "construct":
        procSection[0] = newIdentNode("init")
        for p in m.stmtList:
          procSection[^1] &= p
        procSection[3][0] = newIdentNode("bool")
        procSection[3] &= nnkIdentDefs.newTree(
          newIdentNode("data"),
          newIdentNode("pointer"),
          newEmptyNode()
        )
        var tmpSection = procSection
        procSection = nnkProcDef.newTree(
          nnkPostfix.newTree(
            newIdentNode("*"),
            newIdentNode(newName),
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkFormalParams.newTree(
            newIdentNode("Component")
          ),
          newEmptyNode(),
          newEmptyNode(),
          nnkStmtList.newTree(
            tmpSection,
            nnkObjConstr.newTree(
              newIdentNode("Component"),
              nnkExprColonExpr.newTree(
                newIdentNode("dataType"),
                newLit(dataName),
              ),
              nnkExprColonExpr.newTree(
                newIdentNode("dataPtr"),
                nnkObjConstr.newTree(
                  newIdentNode(dataName)
                )
              ),
              nnkExprColonExpr.newTree(
                newIdentNode("targetLinks"),
                nnkPrefix.newTree(
                  newIdentNode("@"),
                  nnkBracket.newTree(
                    nnkObjConstr.newTree(
                      newIdentNode("ComponentLink"),
                      nnkExprColonExpr.newTree(
                        newIdentNode("event"),
                        newIdentNode("EVENT_INIT")
                      ),
                      nnkExprColonExpr.newTree(
                        newIdentNode("p"),
                        newIdentNode("init")
                      )
                    )
                  )
                )
              )
            )
          )
        )
        for m2 in methods:
          if m2.hasEvent:
            procSection[^1][^1][^1][^1][^1] &= nnkObjConstr.newTree(
              newIdentNode("ComponentLink"),
              nnkExprColonExpr.newTree(
                newIdentNode("event"),
                newIdentNode(m2.event)
              ),
              nnkExprColonExpr.newTree(
                newIdentNode("p"),
                newIdentNode(m2.name)
              )
            )
        for a in m.params[1..^1]:
          procSection[3] &= a
      else:
        if m.hasEvent:
          procSection[3] &= nnkIdentDefs.newTree(
            newIdentNode("data"),
            newIdentNode("pointer"),
            newEmptyNode()
          )
          if m.params[1][1].repr != "void":
            procSection[^1][0] &= nnkIdentDefs.newTree(
                m.params[1][0],
                newEmptyNode(),
                nnkDerefExpr.newTree(
                  nnkCast.newTree(
                    nnkPtrTy.newTree(m.params[1][1]),
                    newIdentNode("data"),
                  )
                )
              )
        else:
          for a in m.params[1..^1]:
            procSection[3] &= a
        for p in m.stmtList:
          procSection[^1] &= p
      result &= procSection

macro component*(head, body: untyped): untyped =
  result = newTree(nnkStmtList)
  let name = $(head.ident)
  let dataName = name & "Data"
  let newName = "new" & name[0].toUpperAscii & name[1..^1]
  var variables: Table[string, NimNode]
  var methods: seq[ComponentMethod]
  for bodyNode in body:
    case bodyNode.kind:
      of nnkVarSection:
        for node in bodyNode:
          variables[node[0].strVal] = node[1]
      of nnkProcDef:
        var tmpMethod: ComponentMethod
        tmpMethod.name = bodyNode[0].strVal
        tmpMethod.params = bodyNode[3]
        tmpMethod.stmtList = bodyNode[^1]
        tmpMethod.hasEvent = tmpMethod.name.startsWith("event")
        if tmpMethod.hasEvent:
          var eventName = ""
          for c in tmpMethod.name:
            if c.isUpperAscii:
              eventName &= "_"
            eventName &= c.toUpperAscii
          tmpMethod.event = eventName
          tmpMethod.name &= name
        methods &= tmpMethod
      else:
        quit("invalid node kind: " & $bodyNode.kind)
  
  var typeSection = nnkTypeSection.newTree(
    nnkTypeDef.newTree(
      nnkPostFix.newTree(
        newIdentNode("*"),
        newIdentNode(dataName)
      ),
      newEmptyNode(),
      nnkRefTy.newTree(
        nnkObjectTy.newTree(
          newEmptyNode(),
          nnkOfInherit.newTree(
            newIdentNode("ComponentData")
          ),
          nnkRecList.newTree(
            # filled in next for loop
          )
        )
      )
    )
  )

  for v in variables.keys:
    typeSection[0][2][0][2] &= nnkIdentDefs.newTree(
      nnkPostfix.newTree(
        newIdentNode("*"),
        newIdentNode(v),
      ),
      variables[v],
      newEmptyNode()
    )
  
  result &= typeSection

  for m in methods:
    var procSection = nnkProcDef.newTree(
      nnkPostfix.newTree(
        newIdentNode("*"),
        newIdentNode(m.name),
      ),
      newEmptyNode(),
      newEmptyNode(),
      nnkFormalParams.newTree(
        m.params[0],
        nnkIdentDefs.newTree(
          newIdentNode("parent"),
          nnkPtrTy.newTree(
            newIdentNode("Entity")
          ),
          newEmptyNode()
        )
      ),
      newEmptyNode(),
      newEmptyNode(),
      nnkStmtList.newTree(
        nnkVarSection.newTree(
          nnkIdentDefs.newTree(
            newIdentNode("this"),
            newEmptyNode(),
            nnkCall.newTree(
              newIdentNode("[]"),
              newIdentNode("parent"),
              newIdentNode(dataName)
            )
          )
        ) 
      )
    )
    if m.name == "construct":
      procSection[0] = newIdentNode("init")
      for p in m.stmtList:
        procSection[^1] &= p
      procSection[3][0] = newIdentNode("bool")
      procSection[3] &= nnkIdentDefs.newTree(
        newIdentNode("data"),
        newIdentNode("pointer"),
        newEmptyNode()
      )
      var tmpSection = procSection
      procSection = nnkProcDef.newTree(
        nnkPostfix.newTree(
          newIdentNode("*"),
          newIdentNode(newName),
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          newIdentNode("Component")
        ),
        newEmptyNode(),
        newEmptyNode(),
        nnkStmtList.newTree(
          tmpSection,
          nnkObjConstr.newTree(
            newIdentNode("Component"),
            nnkExprColonExpr.newTree(
              newIdentNode("dataType"),
              newLit(dataName),
            ),
            nnkExprColonExpr.newTree(
              newIdentNode("dataPtr"),
              nnkObjConstr.newTree(
                newIdentNode(dataName)
              )
            ),
            nnkExprColonExpr.newTree(
              newIdentNode("targetLinks"),
              nnkPrefix.newTree(
                newIdentNode("@"),
                nnkBracket.newTree(
                  nnkObjConstr.newTree(
                    newIdentNode("ComponentLink"),
                    nnkExprColonExpr.newTree(
                      newIdentNode("event"),
                      newIdentNode("EVENT_INIT")
                    ),
                    nnkExprColonExpr.newTree(
                      newIdentNode("p"),
                      newIdentNode("init")
                    )
                  )
                )
              )
            )
          )
        )
      )
      for m2 in methods:
        if m2.hasEvent:
          procSection[^1][^1][^1][^1][^1] &= nnkObjConstr.newTree(
            newIdentNode("ComponentLink"),
            nnkExprColonExpr.newTree(
              newIdentNode("event"),
              newIdentNode(m2.event)
            ),
            nnkExprColonExpr.newTree(
              newIdentNode("p"),
              newIdentNode(m2.name)
            )
          )
      for a in m.params[1..^1]:
        procSection[3] &= a
    else:
      if m.hasEvent:
        procSection[3] &= nnkIdentDefs.newTree(
          newIdentNode("data"),
          newIdentNode("pointer"),
          newEmptyNode()
        )
        if m.params[1][1].repr != "void":
          procSection[^1][0] &= nnkIdentDefs.newTree(
              m.params[1][0],
              newEmptyNode(),
              nnkDerefExpr.newTree(
                nnkCast.newTree(
                  nnkPtrTy.newTree(m.params[1][1]),
                  newIdentNode("data"),
                )
              )
            )
      else:
        for a in m.params[1..^1]:
          procSection[3] &= a
      for p in m.stmtList:
        procSection[^1] &= p
    result &= procSection

proc isPlusNode(node: NimNode): bool =
  node.kind == nnkIdent and $node == "entity"

proc isDashNode(node: NimNode): bool = 
  node.kind == nnkPrefix and $node[0] == "-"

proc prefabAux(outName, args, body: NimNode): NimNode =
  var nodes: seq[NimNode]
  var tmpName = "tmp" & outName.strVal
  result = newNimNode(nnkStmtList)
  result &= newNimNode(nnkVarSection).add(
    newIdentDefs(ident(tmpName), ident("Component")),
  )
  var idx = -1
  var add = newIntLitNode(0)
  var added: seq[int]
  for c in body:
    if c.isDashNode():
      nodes &= c
    elif c.kind == nnkPrefix and $c[0] == ">":
      add = c[1]
      added = @[]
    elif c.kind == nnkPrefix and $c[0] == "<":
      idx += c[1].intVal.int
    elif c.kind == nnkPrefix and $c[0] == "++":
      idx += 1
      var output = nnkBracketExpr.newTree(ident("output"), nnkCall.newTree(newIdentNode("+"), newIntLitNode(idx), add))
      if not(idx in added):
        added &= idx
        result &= newAssignment(output, newCall(ident("newEntity")))
        when defined(hangui):
          result &= nnkCall.newTree(
            newIdentNode("setName"),
            output,
            newLit(outName.strVal & $idx),
          )
      for n in nodes:
        var name = $n[1]
        result &= newAssignment(ident(tmpName), newCall(ident("new" & name)))
        if n.len() > 2:
          for a in n[2]:
            case a.kind:
            of nnkAsgn:
              var assignName = newDotExpr(newDotExpr(ident(tmpName), ident(name)),
                  ident($a[0]))
              var assignValue = a[1]
              result[^1][^1] &= assignValue
            else:
              assert false, "Invalid ast"

        result &= nnkCall.newTree(
          newIdentNode("attachComponent"),
          output,
          newIdentNode(tmpName),
        )
      nodes = @[]
      idx += c[1].intVal.int
    elif c.isPlusNode():
      if nodes == @[]:
        continue
      idx += 1
      var output = nnkBracketExpr.newTree(ident("output"), nnkCall.newTree(newIdentNode("+"), newIntLitNode(idx), add))
      if not(idx in added):
        added &= idx
        result &= newAssignment(output, newCall(ident("newEntity")))
        when defined(hangui):
          result &= nnkCall.newTree(
            newIdentNode("setName"),
            output,
            newLit(outName.strVal & $idx),
          )
      for n in nodes:
        var name = $n[1]
        result &= newAssignment(ident(tmpName), newCall(ident("new" & name)))
        if n.len() > 2:
          for a in n[2]:
            case a.kind:
            of nnkAsgn:
              var assignName = newDotExpr(newDotExpr(ident(tmpName), ident(name)),
                  ident($a[0]))
              var assignValue = a[1]
              result[^1][^1] &= assignValue
            else:
              assert false, "Invalid ast"

        result &= nnkCall.newTree(
          newIdentNode("attachComponent"),
          output,
          newIdentNode(tmpName),
        )
      nodes = @[]
  if nodes != @[]:
    idx += 1
    var output = nnkBracketExpr.newTree(ident("output"), nnkCall.newTree(newIdentNode("+"), newIntLitNode(idx), add))
    if not(idx in added):
      added &= idx
      result &= newAssignment(output, newCall(ident("newEntity")))
      when defined(hangui):
        result &= nnkCall.newTree(
          newIdentNode("setName"),
          output,
          newLit(outName.strVal & $idx),
        )
    for n in nodes:
      var name = $n[1]
      result &= newAssignment(ident(tmpName), newCall(ident("new" & name)))
      if n.len() > 2:
        for a in n[2]:
          case a.kind:
          of nnkAsgn:
            var assignName = newDotExpr(newDotExpr(ident(tmpName), ident(name)),
                ident($a[0]))
            var assignValue = a[1]
            result[^1][^1] &= assignValue
          else:
            assert false, "Invalid ast"
      result &= nnkCall.newTree(
        newIdentNode("attachComponent"),
        output,
        newIdentNode(tmpName),
      )
  result = nnkTemplateDef.newTree(
    nnkPostFix.newTree(
      newIdentNode("*"),
      newIdentNode("spawn" & $outName),
    ),
    newEmptyNode(),
    newEmptyNode(),
    nnkFormalParams.newTree(
      newEmptyNode(),
      nnkIdentDefs.newTree(
        newIdentNode("output"),
        newIdentNode("untyped"),
        newEmptyNode(),
      )
    ),
    newEmptyNode(),
    newEmptyNode(),
    result
  )
  for a in args:
    result[3] &= nnkIdentDefs.newTree(
      a[0],
      a[1],
      newEmptyNode()
    )

macro prefab*(head, args, body: untyped): untyped =
  return prefabAux(head, args, body)

when isMainModule:
  import core/types/rect
  import core/types/texture
  import ecs/types
  import ecs/component as lol
  import ecs/entity
  import ecs/components/spritecomponent
  expandMacros:
    prefab TestPrefab, (r: Rect):
      - SpriteComponent:
        tex = Texture()
        source = r
  var te: ref Entity
  te.newTestPrefab(newRect(0, 0, 10, 10))
