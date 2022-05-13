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

proc primary(parser: var Parser): Expr =
  if parser.match(FALSE): return Literal(value: FalseValue)
  if parser.match(TRUE): return Literal(value: TrueValue)
  if parser.match(NIL): return Literal(value: NullValue)

  if parser.match(NUMBER, STRING):
    return Literal(value: parser.previous.literal)

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

proc factor(parser: var Parser): Expr =
  var expr = parser.unary()

  while parser.match(SLASH, STAR):
    let
      operator = parser.previous
      right = parser.unary()
    expr = Binary(left: expr, operator: operator, right: right)

  expr

proc term(parser: var Parser): Expr =
  var expr = parser.factor()

  while parser.match(MINUS, PLUS):
    let
      operator = parser.previous
      right = parser.factor()
    expr = Binary(left: expr, operator: operator, right: right)

  expr

proc comparison(parser: var Parser): Expr =
  var expr = parser.term()

  while parser.match(GREATER, GREATER_EQUAL, LESS, LESS_EQUAL):
    let
      operator = parser.previous
      right = parser.term()
    expr = Binary(left: expr, operator: operator, right: right)

  expr

# TODO: Investigate how I can metaprogram this
proc equality(parser: var Parser): Expr =
  var expr = parser.comparison()

  while parser.match(BANG_EQUAL, EQUAL_EQUAL):
    let
      operator = parser.previous
      right = parser.comparison()
    expr = Binary(left: expr, operator: operator, right: right)

  expr

proc expression(parser: var Parser): Expr =
  parser.equality()

proc parse*(parser: var Parser): Expr =
  try:
    return parser.expression()
  except ParseError:
    return nil
