import ast, token, value, errors

type
  Parser* = ref object
    tokens: seq[Token]
    current: int

  ParseError = object of CatchableError

proc newParser*(tokens: seq[Token]): Parser =
  Parser(tokens: tokens, current: 0)

func previous(parser: Parser): Token =
  parser.tokens[parser.current - 1]

func peek(parser: Parser): Token =
  parser.tokens[parser.current]

func isAtEnd(parser: Parser): bool =
  parser.peek.tokenType == EOF

proc advance(parser: var Parser): Token =
  if not parser.isAtEnd:
    inc parser.current
  parser.previous

func check(parser: Parser, tokenType: TokenType): bool =
  not parser.isAtEnd and parser.peek.tokenType == tokenType

proc match(parser: var Parser, tokenTypes: varargs[TokenType]): bool =
  for tokenType in tokenTypes:
    if parser.check(tokenType):
      discard parser.advance()
      return true

  false

proc synchronize(parser: var Parser) =
  discard parser.advance()

  while not parser.isAtEnd:
    if parser.previous.tokenType == SEMICOLON: return

    case parser.peek.tokenType
    of CLASS, FUN, VAR, FOR, IF, WHILE, PRINT, RETURN: return
    else: discard

    discard parser.advance()

proc error(parser: Parser, token: Token, message: string): ref ParseError =
  error(token, message)
  return newException(ParseError, "Parse error")

proc consume(parser: var Parser, tokenType: TokenType, message: string): Token =
  if parser.check(tokenType): return parser.advance()

  raise parser.error(parser.peek, message)

proc expression(parser: var Parser): Expr
proc declaration(parser: var Parser): Stmt

proc primary(parser: var Parser): Expr =
  if parser.match(FALSE): return Literal(value: FalseValue)
  if parser.match(TRUE): return Literal(value: TrueValue)
  if parser.match(NIL): return Literal(value: NullValue)

  if parser.match(NUMBER, STRING):
    return Literal(value: parser.previous.literal)

  if parser.match(IDENTIFIER):
    return Variable(name: parser.previous)

  if parser.match(LEFT_PAREN):
    let expr = parser.expression()
    discard parser.consume(RIGHT_PAREN, "Expect ')' after expression.")
    return Grouping(expression: expr)

  raise parser.error(parser.peek, "Expect expression.")


proc unary(parser: var Parser): Expr =
  if parser.match(BANG, MINUS):
    let
      operator = parser.previous
      right = parser.unary()
    return Unary(operator: operator, right: right)

  return parser.primary()

template binaryOperationPair(name, successor, operator1, operator2: untyped) =
  proc name(parser: var Parser): Expr =
    var expr = parser.successor()

    while parser.match(operator1, operator2):
      let
        operator = parser.previous
        right = parser.successor()
      expr = Binary(left: expr, operator: operator, right: right)

    expr

binaryOperationPair(factor, unary, SLASH, STAR)
binaryOperationPair(term, factor, MINUS, PLUS)

proc comparison(parser: var Parser): Expr =
  var expr = parser.term()

  # TODO: this is awkward since I can't put variable number of operators into the template
  while parser.match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL):
    let
      operator = parser.previous
      right = parser.term()
    expr = Binary(left: expr, operator: operator, right: right)

  expr

binaryOperationPair(equality, comparison, BANG_EQUAL, EQUAL_EQUAL)

proc assignment(parser: var Parser): Expr =
  let expr = parser.equality()

  if parser.match(EQUAL):
    let
      equals = parser.previous
      value = parser.assignment()

    if expr of Variable:
      let name = Variable(expr).name
      return Assign(name: name, value: value)

    error(equals, "Invalid assignment target.")

  result = expr

proc expression(parser: var Parser): Expr =
  parser.assignment()

proc printStatement(parser: var Parser): Stmt =
  let value = parser.expression()
  discard parser.consume(SEMICOLON, "Expect ';' after value.")
  return PrintStmt(expression: value)

proc parseBlock(parser: var Parser): seq[Stmt] =
  var statements: seq[Stmt] = @[]

  while not parser.check(RIGHT_BRACE) and not parser.isAtEnd:
    statements.add(parser.declaration())

  discard parser.consume(RIGHT_BRACE, "Expect '}' after block.")
  result = statements

proc expressionStatement(parser: var Parser): Stmt =
  let expr = parser.expression()
  discard parser.consume(SEMICOLON, "Expect ';' after expression.")
  return ExpressionStmt(expression: expr)

proc statement(parser: var Parser): Stmt =
  if parser.match(PRINT): return parser.printStatement()
  if parser.match(LEFT_BRACE): return BlockStmt(statements: parser.parseBlock())

  parser.expressionStatement()

proc varDeclaration(parser: var Parser): Stmt =
  let name = parser.consume(IDENTIFIER, "Expect variable name.")

  var initializer: Expr = nil
  if parser.match(EQUAL):
    initializer = parser.expression()

  discard parser.consume(SEMICOLON, "Expect ';' after variable declaration")
  return VarStmt(name: name, initializer: initializer)

proc declaration(parser: var Parser): Stmt =
  try:
    if parser.match(VAR): return parser.varDeclaration()

    return parser.statement()
  except ParseError:
    parser.synchronize()
    return nil

proc parse*(parser: var Parser): seq[Stmt] =
  var statements: seq[Stmt] = @[]

  while not parser.isAtEnd:
    statements.add(parser.declaration())

  statements
