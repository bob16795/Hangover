import ../core/events

createEvent(EVENT_FSM_CHANGE)

type
  StateMachine* = object
    currentState*: int
    states: seq[StateMachineState]
  StateMachineState* = object
    conds: seq[Flag]
  Flag* = object
    id: int
    nextState: int
    value: bool

var gameMachine*: StateMachine

proc initFlag*(id, next: int): Flag =
  result.id = id
  result.nextState = next

proc initState*(flags: seq[Flag]): StateMachineState =
  result.conds = flags

proc initStateMachine*(states: seq[StateMachineState]): StateMachine =
  result.states = states
  result.currentState = 0

proc checkConds*(sms: StateMachineState): bool =
  for cond in sms.conds:
    if cond.value:
      return true
  return false

proc checkCondsNext*(sms: StateMachineState): int =
  for cond in sms.conds:
    if cond.value:
      return cond.nextState
  return -1

proc setFlag*(sm: var StateMachine, id: int) =
  for i in 0..<sm.states[sm.currentState].conds.len:
    if sm.states[sm.currentState].conds[i].id == id:
      sm.states[sm.currentState].conds[i].value = true
  if sm.states[sm.currentState].checkConds():
    sm.currentState = sm.states[sm.currentState].checkCondsNext();
  for i in 0..<sm.states[sm.currentState].conds.len:
    sm.states[sm.currentState].conds[i].value = false
  sendEvent(EVENT_FSM_CHANGE, addr sm.currentState)
