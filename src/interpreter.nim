import ast, token, value, errors

type
  Interpreter* = ref object of Visitor
    discard

  RuntimeError = object of CatchableError
    token: Token

proc newRuntimeError(token: Token, message: string): ref RuntimeError =
  (ref RuntimeError)(token: token, msg: message, parent: nil)

proc checkNumberOperand(operator: Token, operand: Value) =
  if operand.kind == vkNumber: return
  raise newRuntimeError(operator, "Operand must be a number.")

proc checkNumberOperands(operator: Token, left: Value, right: Value) =
  if left.kind == vkNumber and right.kind == vkNumber: return
  raise newRuntimeError(operator, "Operands must be numbers.")

proc evaluate(visitor: Interpreter, expr: Expr): Value =
  expr.accept(visitor)

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

proc interpret*(interpreter: Interpreter, expression: Expr) =
  try:
    let value = interpreter.evaluate(expression)
    echo $value
  except RuntimeError as e:
    runtimeError(e.token, e.msg)