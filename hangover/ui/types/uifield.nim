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
        getter*: proc (): T
        setter*: proc (data: T)

template UIFieldValue*[T](data: static[T]): UIField[T] =
  let tmp = data

  capture tmp:
    UIField[T](
      kind: staticv,
      this: tmp,
    )

proc UIFieldGetter*[T](getter: proc(): T): UIField[T] =
  UIField[T](
    kind: dynamic,
    getter: getter,
  )

template UIFieldFrom*(value: untyped): untyped =
  type T = typeof(value)

  UIField[T](
    kind: dynamic,
    getter: proc(): T =
      value,
    setter: proc(n: T) =
      value = n,
  )

proc `value`*[T](a: var UIField[T]): T =
  case a.kind:
  of default: return
  of staticv: return a.this
  of dynamic: return a.getter()

proc `value=`*[T](a: var UIField[T], b: T) =
  case a.kind:
  of default: discard
  of staticv: a.this = b
  of dynamic: a.setter(b)
