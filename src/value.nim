import strutils

type
  Callable* = ref object of RootObj
  ClockCallable* = ref object of Callable

method arity*(callable: Callable): int {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method `$`*(callable: Callable): string {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method arity*(callable: ClockCallable): int = 0

method `$`*(callable: ClockCallable): string = "<native fn>"

type
  ValueKind* = enum
    vkString,
    vkNumber,
    vkBoolean,
    vkCallable,
    vkNull,
  Value* = object
    case kind*: ValueKind
    of vkString: strVal*: string
    of vkNumber: numberVal*: float
    of vkBoolean: boolVal*: bool
    of vkCallable: callableVal*: Callable
    of vkNull: discard

proc stringValue*(value: string): Value =
  Value(kind: vkString, strVal: value)

proc numberValue*(value: float): Value =
  Value(kind: vkNumber, numberVal: value)

proc booleanValue*(value: bool): Value =
  Value(kind: vkBoolean, boolVal: value)

var
  NullValue* = Value(kind: vkNull)
  TrueValue* = booleanValue(true)
  FalseValue* = booleanValue(false)

proc `$`*(value: Value): string =
  case value.kind
  of vkString: result = value.strVal
  of vkNumber:
    result = $value.numberVal
    result.removeSuffix(".0")
  of vkBoolean: result = $value.boolVal
  of vkCallable: result = $value.callableVal
  of vkNull: result = "nil"

func isTruthy*(value: Value): bool =
  case value.kind
  of vkString, vkNumber, vkCallable: result = true
  of vkBoolean: result = value.boolVal
  of vkNull: result = false

func `==`*(value1, value2: Value): bool =
  if value1.kind != value2.kind:
    return false
  case value1.kind
  of vkString: result = value1.strVal == value2.strVal
  of vkNumber: result = value1.numberVal == value2.numberVal
  of vkBoolean: result = value1.boolVal == value2.boolVal
  of vkCallable: result = value1.callableVal == value2.callableVal
  of vkNull: result = true
