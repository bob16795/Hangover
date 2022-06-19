import macros
import tables
import core/events
import strutils
import types

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
          echo "link: " & m2.event
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
        if m.params[1][1].strVal != "void":
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

  echo result.repr


when isMainModule:
  import components/uirectcomponent
  import component as componentClass
  import entity
  import math
  import core/templates

  const
    BAR_SPEED = 10
  expandMacros:
    component SmoothBarComponent:
      var
        goal: float32
        max: float32
        value: float32
        id: int
        click: float32

      proc setGoal(value: float32, instant: bool) =
        this.goal = value
        if instant:
          this.value = value

      proc setMax(value: float32) =
        this.value = value

      proc eventUpdate(dt: float32): bool =
        var rect = parent[UIRectComponentData]
      
        if dt >= BAR_SPEED:
          this.value = this.goal / this.max
        else:
          let diff = this.value - (this.goal / this.max)
          this.value -= diff / BAR_SPEED * dt
       
        if this.click != 0: rect.rect.anchorXMax = clamp(this.value - (this.value mod (this.click / this.max)), 0, 1)
        else: rect.rect.anchorXMax = clamp(this.value, 0, 1)
        updateRectComponent(parent)

      proc construct(click: float32) =
        this.click = click

  dumpAstGen:    
    type
      SmoothBarComponentData* = ref object of ComponentData
        goal: float32
        max: float32
        value: float32
        id: int
        click: float32
    
    method setGoal*(this: SmoothBarComponentData, value: float32, instant: bool) =
      this.goal = value
      if instant:
        this.value = value
    
    method setMax*(this: SmoothBarComponentData, value: float32) =
      this.max = value
    
    proc updateSmoothBarComponent*(parent: ptr Entity, data: pointer): bool =
      var this = parent[SmoothBarComponentData]
      let dt = cast[ptr float32](data)[]
      var rect = parent[UIRectComponentData]
    
      if dt >= BAR_SPEED:
        this.value = this.goal / this.max
      else:
        let diff = this.value - (this.goal / this.max)
        this.value -= diff / BAR_SPEED * dt
      
      if this.click != 0: rect.rect.anchorXMax = clamp(this.value - (this.value mod (this.click / this.max)), 0, 1)
      else: rect.rect.anchorXMax = clamp(this.value, 0, 1)
      updateRectComponent(parent)
    
    proc newSmoothBarComponent*(click: float32 = 0): Component = 
      Component(
        dataType: "SmoothBarComponentData",
        targetLinks:
        @[
          ComponentLink(event: EVENT_UPDATE, p: updateSmoothBarComponent),
          ComponentLink(event: EVENT_INIT, p: proc(parent: ptr Entity, data: pointer): bool =
            parent[SmoothBarComponentData] = SmoothBarComponentData()
            parent[SmoothBarComponentData].click = click
          ),
        ]
      )
