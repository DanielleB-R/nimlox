import ast, token, value, errors, environment, sequtils, times

type
  Return* = object of CatchableError
    value*: Value

proc newReturn*(value: Value): ref Return =
  (ref Return)(value: value, parent: nil)


type
  Interpreter* = ref object of Visitor
    environment: Environment
    globals: Environment

type
  LoxFunction = ref object of Callable
    declaration: FunctionStmt
    closure: Environment

method arity(callable: LoxFunction): int =
  callable.declaration.params.len

method `$`(callable: LoxFunction): string =
  "<fn " & callable.declaration.name.lexeme & ">"

# Put the methods on Callable here to make them work lol
method call(callable: Callable, interpreter: Interpreter, arguments: seq[Value]): Value {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method call(callable: ClockCallable, interpreter: Interpreter, arguments: seq[Value]): Value =
  Value(kind: vkNumber, numberVal: cpuTime())

proc executeBlock(interpreter: Interpreter, statements: seq[Stmt],
    env: Environment)

method call(callable: LoxFunction, interpreter: Interpreter, arguments: seq[Value]): Value =
  var environment = newEnvironment(callable.closure)
  for (arg, param) in zip(arguments, callable.declaration.params):
    environment.define(param.lexeme, arg)
  try:
    interpreter.executeBlock(callable.declaration.body, environment)
  except Return as ret:
    return ret.value
  result = NullValue

proc newInterpreter*(): Interpreter =
  var globals = newEnvironment()
  globals.define("clock", Value(kind: vkCallable, callableVal: ClockCallable()))
  Interpreter(environment: globals, globals: globals)

proc checkNumberOperand(operator: Token, operand: Value) =
  if operand.kind == vkNumber: return
  raise newRuntimeError(operator, "Operand must be a number.")

proc checkNumberOperands(operator: Token, left: Value, right: Value) =
  if left.kind == vkNumber and right.kind == vkNumber: return
  raise newRuntimeError(operator, "Operands must be numbers.")

proc evaluate(visitor: Interpreter, expr: Expr): Value =
  expr.accept(visitor)

method visitCall(visitor: Interpreter, expr: Call): Value =
  let
    callee = visitor.evaluate(expr.callee)
    arguments = expr.arguments.mapIt(visitor.evaluate(it))

  if callee.kind != vkCallable:
    raise newRuntimeError(expr.paren, "Can only call functions and classes.")

  if arguments.len != callee.callableVal.arity:
    raise newRuntimeError(expr.paren, "Expected " & $callee.callableVal.arity & " arguments but got " & $arguments.len & ".")

  result = callee.callableVal.call(visitor, arguments)


method visitLiteral(visitor: Interpreter, expr: Literal): Value =
  expr.value

method visitGrouping(visitor: Interpreter, expr: Grouping): Value =
  visitor.evaluate(expr.expression)

method visitUnary(visitor: Interpreter, expr: Unary): Value =
  let right = visitor.evaluate(expr.right)

  case expr.operator.tokenType
  of BANG: return booleanValue(not right.isTruthy)
  of MINUS:
    checkNumberOperand(expr.operator, right)
    return numberValue(-right.numberVal)
  else: discard

  nil

method visitVariable(visitor: Interpreter, expr: Variable): Value =
  visitor.environment.get(expr.name)

method visitBinary(visitor: Interpreter, expr: Binary): Value =
  let
    left = visitor.evaluate(expr.left)
    right = visitor.evaluate(expr.right)

  case expr.operator.tokenType
  of GREATER:
    checkNumberOperands(expr.operator, left, right)
    return booleanValue(left.numberVal > right.numberVal)
  of GREATER_EQUAL:
    checkNumberOperands(expr.operator, left, right)
    return booleanValue(left.numberVal >= right.numberVal)
  of LESS:
    checkNumberOperands(expr.operator, left, right)
    return booleanValue(left.numberVal < right.numberVal)
  of LESS_EQUAL:
    checkNumberOperands(expr.operator, left, right)
    return booleanValue(left.numberVal <= right.numberVal)
  of EQUAL_EQUAL: return booleanValue(left == right)
  of BANG_EQUAL: return booleanValue(left != right)
  of MINUS:
    checkNumberOperands(expr.operator, left, right)
    return numberValue(left.numberVal - right.numberVal)
  of SLASH:
    checkNumberOperands(expr.operator, left, right)
    return numberValue(left.numberVal / right.numberVal)
  of STAR:
    checkNumberOperands(expr.operator, left, right)
    return numberValue(left.numberVal * right.numberVal)
  of PLUS:
    if left.kind == vkNumber and right.kind == vkNumber:
      return numberValue(left.numberVal + right.numberVal)

    if left.kind == vkString and right.kind == vkString:
      return stringValue(left.strVal & right.strVal)

    raise newRuntimeError(expr.operator, "Operands must be two numbers or two strings")

  else: discard

  nil

method visitLogical(interpreter: Interpreter, expr: Logical): Value =
  let left = interpreter.evaluate(expr.left)

  if expr.operator.token_type == OR:
    if left.isTruthy:
      return left
  else:
    if not left.isTruthy:
      return left

  interpreter.evaluate(expr.right)

method visitAssign(interpreter: Interpreter, expr: Assign): Value =
  let value = interpreter.evaluate(expr.value)
  interpreter.environment.assign(expr.name, value)
  result = value

proc execute(interpreter: Interpreter, statement: Stmt) =
  discard statement.accept(interpreter)

proc executeBlock(interpreter: Interpreter, statements: seq[Stmt],
    env: Environment) =
  let previous = interpreter.environment
  try:
    interpreter.environment = env
    for statement in statements:
      interpreter.execute(statement)
  finally:
    interpreter.environment = previous

method visitBlockStmt(interpreter: Interpreter, stmt: BlockStmt): Value =
  interpreter.executeBlock(stmt.statements, newEnvironment(
      interpreter.environment))
  nil

method visitExpressionStmt(interpreter: Interpreter,
    stmt: ExpressionStmt): Value =
  discard interpreter.evaluate(stmt.expression)
  nil

method visitFunctionStmt(interpreter: Interpreter, stmt: FunctionStmt): Value =
  let function = LoxFunction(declaration: stmt, closure: environment)
  interpreter.environment.define(stmt.name.lexeme, Value(kind: vkCallable, callableVal: function))
  nil

method visitIfStmt(interpreter: Interpreter, stmt: IfStmt): Value =
  if interpreter.evaluate(stmt.condition).isTruthy:
    interpreter.execute(stmt.thenBranch)
  elif stmt.elseBranch != nil:
    interpreter.execute(stmt.elseBranch)

  nil

method visitPrintStmt(interpreter: Interpreter, stmt: PrintStmt): Value =
  let value = interpreter.evaluate(stmt.expression)
  echo $value
  nil

method visitReturnStmt(interpreter: Interpreter, stmt: ReturnStmt): Value =
  var value = NullValue
  if stmt.value != nil: value = interpreter.evaluate(stmt.value)

  raise newReturn(value)

method visitVarStmt(interpreter: Interpreter, stmt: VarStmt): Value =
  var value = NullValue
  if stmt.initializer != nil:
    value = interpreter.evaluate(stmt.initializer)

  interpreter.environment.define(stmt.name.lexeme, value)
  nil

method visitWhileStmt(interpreter: Interpreter, stmt: WhileStmt): Value =
  while interpreter.evaluate(stmt.condition).isTruthy:
    interpreter.execute(stmt.body)
  nil

proc interpret*(interpreter: Interpreter, statements: seq[Stmt]) =
  try:
    for statement in statements:
      interpreter.execute(statement)
  except RuntimeError as e:
    runtimeError(e.token, e.msg)
