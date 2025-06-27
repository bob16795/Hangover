import sugar

type
  UIFieldKind* = enum
    default
    staticv
    dynamic

  UIField*[T] = object
    case kind*: UIFieldKind
      of default: discard
      of staticv:
        this*: T
      of dynamic:
        getter*: proc (): T {.gcsafe.}
        setter*: proc (data: T) {.gcsafe.}

template fieldValue*[T](data: static[T]): UIField[T] =
  let tmp = data

  capture tmp:
    UIField[T](
      kind: staticv,
      this: tmp,
    )

proc fieldGetter*[T](getter: proc(): T): UIField[T] =
  UIField[T](
    kind: dynamic,
    getter: getter,
  )

template fieldVar*(value: untyped): untyped =
  type T = typeof(value)

  UIField[T](
    kind: dynamic,
    getter: proc(): T {.gcsafe.} =
      value,
    setter: proc(n: T) {.gcsafe.} =
      value = n,
  )

proc `value`*[T](a: var UIField[T]): T {.gcsafe.} =
  case a.kind:
  of default: return
  of staticv: return a.this
  of dynamic: return a.getter()

proc `value=`*[T](a: var UIField[T], b: T) {.gcsafe.} =
  case a.kind:
  of default: discard
  of staticv: a.this = b
  of dynamic: a.setter(b)
