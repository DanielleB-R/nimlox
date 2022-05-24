import token, value

type
  Expr* = ref object of RootObj

  Assign* = ref object of Expr
    name*: Token
    value*: Expr

  Binary* = ref object of Expr
    left*: Expr
    operator*: Token
    right*: Expr

  Grouping* = ref object of Expr
    expression*: Expr

  Literal* = ref object of Expr
    value*: Value

  Logical* = ref object of Expr
    left*: Expr
    operator*: Token
    right*: Expr

  Unary* = ref object of Expr
    operator*: Token
    right*: Expr

  Variable* = ref object of Expr
    name*: Token

type
  Stmt* = ref object of RootObj

  BlockStmt* = ref object of Stmt
    statements*: seq[Stmt]

  ExpressionStmt* = ref object of Stmt
    expression*: Expr

  IfStmt* = ref object of Stmt
    condition*: Expr
    thenBranch*: Stmt
    elseBranch*: Stmt

  PrintStmt* = ref object of Stmt
    expression*: Expr

  VarStmt* = ref object of Stmt
    name*: Token
    initializer*: Expr

  WhileStmt* = ref object of Stmt
    condition*: Expr
    body*: Stmt

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

visitorMethods(Assign)
visitorMethods(Binary)
visitorMethods(Grouping)
visitorMethods(Literal)
visitorMethods(Logical)
visitorMethods(Unary)
visitorMethods(Variable)
visitorMethods(BlockStmt)
visitorMethods(ExpressionStmt)
visitorMethods(IfStmt)
visitorMethods(PrintStmt)
visitorMethods(VarStmt)
visitorMethods(WhileStmt)
