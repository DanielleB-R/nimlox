import token, value

type
  Expr* = ref object of RootObj
    discard

  Binary* = ref object of Expr
    left*: Expr
    operator*: Token
    right*: Expr

  Grouping* = ref object of Expr
    expression*: Expr

  Literal* = ref object of Expr
    value*: Value

  Unary* = ref object of Expr
    operator*: Token
    right*: Expr

type
  Visitor* = ref object of RootObj
    discard

method accept*(expr: Expr, visitor: Visitor): Value {.base.} =
  raise newException(CatchableError, "Method without implementation override")

template visitorMethods(typename: untyped) =
  method `visit typename`*(visitor: Visitor, expr: typename): Value {.base.} =
    raise newException(CatchableError, "Method without implementation override")
  method accept*(expr: typename, visitor: Visitor): Value =
    visitor.`visit typename`(expr)

visitorMethods(Binary)
visitorMethods(Grouping)
visitorMethods(Literal)
visitorMethods(Unary)