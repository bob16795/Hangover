import ../core/events

createEvent(EVENT_FSM_CHANGE)

type
  StateMachine* = object
    ## A state machine 
    currentState*: int
    ## The current state machine state
    states: seq[StateMachineState]
  StateMachineState* = object
    conds: seq[Flag]
  Flag* = object
    ## a state machine flag
    id: int
    nextState: int
    value: bool

proc newFlag*(id, next: int): Flag =
  ## creates a new state machine flag
  ## `id`: the signal to trigger the flag
  ## `next`: the next state to go to
  result.id = id
  result.nextState = next

proc newState*(flags: seq[Flag]): StateMachineState =
  ## Inits a state machine state
  result.conds = flags

proc newStateMachine*(states: seq[StateMachineState]): StateMachine =
  ## Creates a state machine
  result.states = states
  result.currentState = 0

proc initFlag*(id, next: int): Flag {.deprecated.} =
  newFlag(id, next)

proc initState*(flags: seq[Flag]): StateMachineState {.deprecated.} =
  newState(flags)

proc initStateMachine*(states: seq[StateMachineState]): StateMachine {.deprecated.} =
  newStateMachine(states)

proc checkConds(sms: StateMachineState): bool =
  ## checks for the next state machine state
  for cond in sms.conds:
    if cond.value:
      return true
  return false

proc checkCondsNext(sms: StateMachineState): int =
  ## gets the next state
  for cond in sms.conds:
    if cond.value:
      return cond.nextState
  return -1

proc setFlag*(sm: var StateMachine, id: int) =
  ## triggerss a state machine flag
  for i in 0..<sm.states[sm.currentState].conds.len:
    if sm.states[sm.currentState].conds[i].id == id:
      sm.states[sm.currentState].conds[i].value = true
  if sm.states[sm.currentState].checkConds():
    sm.currentState = sm.states[sm.currentState].checkCondsNext();
  for i in 0..<sm.states[sm.currentState].conds.len:
    sm.states[sm.currentState].conds[i].value = false
  sendEvent(EVENT_FSM_CHANGE, addr sm.currentState)
