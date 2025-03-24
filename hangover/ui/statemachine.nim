import ../core/events
import options

createEvent[HSlice[int, int]] eventFsmChange

type
  StateMachine*[S, F] = object
    ## A state machine
    currentState: S
    ## The current state machine state
    states: array[S, StateMachineState[S, F]]
    ## the next flag to trigger on update
    flag: Option[F]

  StateMachineState*[S, F] = object
    conds: array[F, Option[S]]

  Flag*[S, F] = object
    ## a state machine flag
    id: F
    nextState: S

proc newFlag*[S, F](id: F, nextState: S): Flag[S, F] =
  ## creates a new state machine flag
  ## `id`: the signal to trigger the flag
  ## `next`: the next state to go to
  result.id = F(id)
  result.nextState = nextState

proc newState*[S, F](flags: varargs[Flag[S, F]]): StateMachineState[S, F] =
  ## Inits a state machine state
  for flag in flags:
    result.conds[flag.id] = some(flag.nextState)

proc newStateMachine*[S, F](states: array[S, StateMachineState[S, F]]): StateMachine[S, F] =
  ## Creates a state machine
  result.states = states
  result.currentState = 0.S

proc initFlag*[S, F](id: F, next: S): Flag[S, F] {.deprecated.} =
  newFlag(id, next)

proc initState*[S, F](flags: array[F, Option[S]]): StateMachineState[S, F] {.deprecated.} =
  newState(flags)

proc initStateMachine*[S, F](states: seq[StateMachineState[S, F]]): StateMachine[S, F] {.deprecated.} =
  newStateMachine(states)

proc checkConds[S, F](sms: StateMachineState[S, F]): bool =
  ## checks for the next state machine state
  for cond in sms.conds:
    if cond.value:
      return true
  return false

proc setFlag*[S, F](sm: var StateMachine[S, F], id: F) =
  sm.flag = some(id)

proc update*[S, F](sm: var StateMachine[S, F]) =
  sm.flag.map do (flagId: F):
    ## triggerss a state machine flag
    let
      startState = sm.currentState.int
      id = sm.flag.get()
    
    sm.states[startState][flagId.int].map do (newState: S):
      sm.currentState = newState
      eventFsmChange.send((startState.int)..(newState.int))
  sm.flag = none[F]()

proc contains*[S, F](states: set[S], sm: StateMachine[S, F]): bool =
  sm.currentState in states

proc forceState*[S, F](sm: var StateMachine[S, F], state: S) =
  sm.currentState = state

proc `currentState=`*[S, F](sm: var StateMachine[S, F], state: S) =
  if sm.currentState != state:
    let start = sm.currentState
    sm.currentState = state

    eventFsmChange.send(start.int..state.int)

proc getState*[S, F](sm: StateMachine[S, F]): S =
  sm.currentState
