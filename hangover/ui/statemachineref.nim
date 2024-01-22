import ../core/events
import options

createEvent(EVENT_RFSM_CHANGE)

type
  RStateMachine*[S] = object
    currentState: S
    states: array[S, RStateMachineState[S]]

  RStateMachineState*[S] = ref object of RootObj
    ## a state machine state
    conds*: seq[RStateMachineFlag[S]]

  RStateMachineFlag*[S] = object
    ## a state machine flag
    id: int
    nextState: S
    value: bool

method init*(state: var RStateMachineState) {.base.} =
  discard

method deinit*(state: var RStateMachineState) {.base.} =
  discard

proc newRFlag*[S](id: int, next: S): RStateMachineFlag[S] =
  ## creates a new state machine flag
  ## `id`: the signal to trigger the flag
  ## `next`: the next state to go to
  result.id = id
  result.nextState = next

proc newRState*[S](flags: seq[RStateMachineFlag[S]]): RStateMachineState[S] =
  ## Inits a state machine state
  result = RStateMachineState[S]()
  result.conds = flags

proc newRStateMachine*[S](states: array[S, RStateMachineState[S]]): RStateMachine[S] =
  ## Creates a state machine
  result.states = states
  result.currentState = 0.S
  result.states[0.S].init()

proc checkConds[S](sms: RStateMachineState[S]): bool =
  ## checks for the next state machine state
  for cond in sms.conds:
    if cond.value:
      return true
  return false

proc checkCondsNext[S](sms: RStateMachineState[S]): Option[S] =
  ## gets the next state
  for cond in sms.conds:
    if cond.value:
      return some(cond.nextState)
  return none[S]()

proc setFlag*(sm: var RStateMachine, id: int) =
  ## triggerss a state machine flag
  var data = [sm.currentState, sm.currentState]
  for i in 0..<sm.states[sm.currentState].conds.len:
    if sm.states[sm.currentState].conds[i].id == id:
      sm.states[sm.currentState].conds[i].value = true
  if sm.states[sm.currentState].checkConds():
    sm.currentState = sm.states[sm.currentState].checkCondsNext().get
  for i in 0..<sm.states[sm.currentState].conds.len:
    sm.states[sm.currentState].conds[i].value = false
  if data[0] != data[1]:
    data[0].deinit()
    data[1].init()
  if sm.currentState != data[1]:
    data[1] = sm.currentState
    sendEvent(EVENT_RFSM_CHANGE, addr data)

proc contains*[S](states: set[S], sm: RStateMachine[S]): bool =
  sm.currentState in states

proc `currentState=`*[S](sm: var RStateMachine[S], state: S) =
  sm.currentState = state

proc getStateData*[S](sm: RStateMachine[S]): RStateMachineState[S] =
  sm.states[sm.currentState]
