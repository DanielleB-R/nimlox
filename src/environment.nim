import tables, value, errors, token

type
  Environment* = ref object
    values: Table[string, Value]
    enclosing: Environment

proc newEnvironment*(enclosing: Environment): Environment =
  Environment(values: initTable[string, Value](), enclosing: enclosing)

proc newEnvironment*(): Environment =
  newEnvironment(nil)

proc define*(env: var Environment, name: string, value: Value) =
  env.values[name] = value

func get*(env: Environment, name: Token): Value =
  if name.lexeme in env.values:
    return env.values[name.lexeme]

  if env.enclosing != nil:
    return env.enclosing.get(name)

  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")

proc assign*(env: var Environment, name: Token, value: Value) =
  if name.lexeme in env.values:
    env.values[name.lexeme] = value
    return

  if env.enclosing != nil:
    env.enclosing.assign(name, value)
    return

  raise newRuntimeError(name, "Undefined variable '" & name.lexeme & "'.")
