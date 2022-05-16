import tables, value, errors, token

type
  Environment* = object
    values: Table[string, Value]

proc newEnvironment*(): Environment =
  Environment(values: initTable[string, Value]())

proc define*(env: var Environment, name: string, value: Value) =
  env.values[name] = value

func get*(env: Environment, name: Token): Value =
  if name.lexeme in env.values:
    return env.values[name.lexeme]

  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")

proc assign*(env: var Environment, name: Token, value: Value) =
  if name.lexeme in env.values:
    env.values[name.lexeme] = value
    return

  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")
