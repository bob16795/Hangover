import ../core/events
import options

createEvent(EVENT_FSM_CHANGE)

type
  StateMachine*[S] = object
    ## A state machine
    currentState: S
    ## The current state machine state
    states: array[S, StateMachineState[S]]
    ## the next flag to trigger on update
    flag: Option[int]

  StateMachineState*[S] = object
    conds: seq[Flag[S]]
  Flag*[S] = object
    ## a state machine flag
    id: int
    nextState: S
    value: bool

proc newFlag*[S](id: int, next: S): Flag[S] =
  ## creates a new state machine flag
  ## `id`: the signal to trigger the flag
  ## `next`: the next state to go to
  result.id = id
  result.nextState = next

proc newState*[S](flags: varargs[Flag[S]]): StateMachineState[S] =
  ## Inits a state machine state
  for flag in flags:
    result.conds &= flag

proc newStateMachine*[S](states: array[S, StateMachineState[S]]): StateMachine[S] =
  ## Creates a state machine
  result.states = states
  result.currentState = 0.S

proc initFlag*[S](id: int, next: S): Flag[S] {.deprecated.} =
  newFlag(id, next)

proc initState*[S](flags: seq[Flag[S]]): StateMachineState[S] {.deprecated.} =
  newState(flags)

proc initStateMachine*[S](states: seq[StateMachineState[S]]): StateMachine[S] {.deprecated.} =
  newStateMachine(states)

proc checkConds[S](sms: StateMachineState[S]): bool =
  ## checks for the next state machine state
  for cond in sms.conds:
    if cond.value:
      return true
  return false

proc checkCondsNext[S](sms: StateMachineState[S]): Option[S] =
  ## gets the next state
  for cond in sms.conds:
    if cond.value:
      return some(cond.nextState)
  return none[S]()

proc setFlag*(sm: var StateMachine, id: int) =
  sm.flag = some(id)

proc update*(sm: var StateMachine) =
  if sm.flag.isSome():
    ## triggerss a state machine flag
    var id = sm.flag.get()
    sm.flag = none[int]()

    var data = [sm.currentState, sm.currentState]
    for i in 0..<sm.states[sm.currentState].conds.len:
      if sm.states[sm.currentState].conds[i].id == id:
        sm.states[sm.currentState].conds[i].value = true
    if sm.states[sm.currentState].checkConds():
      sm.currentState = sm.states[sm.currentState].checkCondsNext().get
    for i in 0..<sm.states[sm.currentState].conds.len:
      sm.states[sm.currentState].conds[i].value = false
    if sm.currentState != data[1]:
      data[1] = sm.currentState
      sendEvent(EVENT_FSM_CHANGE, addr data)

proc contains*[S](states: set[S], sm: StateMachine[S]): bool =
  sm.currentState in states

proc `currentState=`*[S](sm: var StateMachine[S], state: S) =
  sm.currentState = state

proc getState*[S](sm: StateMachine[S]): S =
  sm.currentState
