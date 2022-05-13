type
  ValueKind* = enum
    vkString,
    vkNumber,
    vkBoolean,
    vkNull,
  Value* = object
    case kind*: ValueKind
    of vkString: strVal*: string
    of vkNumber: numberVal*: float
    of vkBoolean: boolVal*: bool
    of vkNull: discard

proc stringValue*(value: string): Value =
  result = Value(kind: vkString, strVal: value)

proc numberValue*(value: float): Value =
  result = Value(kind: vkNumber, numberVal: value)

const
  NullValue* = Value(kind: vkNull)
  TrueValue* = Value(kind: vkBoolean, boolVal: true)
  FalseValue* = Value(kind: vkBoolean, boolVal: false)

proc `$`*(value: Value): string =
  case value.kind
  of vkString: result = value.strVal
  of vkNumber: result = $value.numberVal
  of vkBoolean: result = $value.boolVal
  of vkNull: result = "nil"
