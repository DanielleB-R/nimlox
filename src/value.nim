type
  ValueKind* = enum
    vkString,
    vkNumber,
    vkNull,
  Value* = object
    case kind: ValueKind
    of vkString: strVal: string
    of vkNumber: numberVal: float
    of vkNull: discard

proc stringValue*(value: string): Value =
  result = Value(kind: vkString, strVal: value)

proc numberValue*(value: float): Value =
  result = Value(kind: vkNumber, numberVal: value)

const NullValue* = Value(kind: vkNull)

proc `$`*(value: Value): string =
  case value.kind
  of vkString: result = value.strVal
  of vkNumber: result = $value.numberVal
  of vkNull: result = "nil"
