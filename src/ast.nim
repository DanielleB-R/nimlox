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

  Call* = ref object of Expr
    callee*: Expr
    paren*: Token
    arguments*: seq[Expr]

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

  FunctionStmt* = ref object of Stmt
    name*: Token
    params*: seq[Token]
    body*: seq[Stmt]

  IfStmt* = ref object of Stmt
    condition*: Expr
    thenBranch*: Stmt
    elseBranch*: Stmt

  PrintStmt* = ref object of Stmt
    expression*: Expr

  ReturnStmt* = ref object of Stmt
    keyword*: Token
    value*: Expr

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
visitorMethods(Call)
visitorMethods(Grouping)
visitorMethods(Literal)
visitorMethods(Logical)
visitorMethods(Unary)
visitorMethods(Variable)
visitorMethods(BlockStmt)
visitorMethods(ExpressionStmt)
visitorMethods(FunctionStmt)
visitorMethods(IfStmt)
visitorMethods(PrintStmt)
visitorMethods(ReturnStmt)
visitorMethods(VarStmt)
visitorMethods(WhileStmt)
