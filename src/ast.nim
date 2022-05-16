import token, value

type
  Expr* = ref object of RootObj

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

  Variable* = ref object of Expr
    name*: Token

type
  Stmt* = ref object of RootObj

  ExpressionStmt* = ref object of Stmt
    expression*: Expr

  PrintStmt* = ref object of Stmt
    expression*: Expr

  VarStmt* = ref object of Stmt
    name*: Token
    initializer*: Expr

type
  Visitor* = ref object of RootObj

method accept*(expr: Expr, visitor: Visitor): Value {.base.} =
  raise newException(CatchableError, "Method without implementation override")

method accept*(stmt: Stmt, visitor: Visitor): Value {.base.} =
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
visitorMethods(Variable)
visitorMethods(ExpressionStmt)
visitorMethods(PrintStmt)
visitorMethods(VarStmt)
