import token, errors

type
  Scanner* = ref object
    source: string
    tokens: seq[Token]
    start: int
    current: int
    line: int

proc newScanner*(source: string): Scanner =
  return Scanner(source: source, tokens: @[], start: 0, current: 0, line: 1)

func isAtEnd(scanner: Scanner): bool =
  return scanner.current >= scanner.source.len

proc advance(scanner: var Scanner): char =
  result = scanner.source[scanner.current]
  inc scanner.current

proc addToken(scanner: var Scanner, tokenType: TokenType, literal: string) =
  let text = scanner.source[scanner.start ..< scanner.current]
  scanner.tokens.add(Token(tokenType: tokenType, lexeme: text, literal: literal, line: scanner.line))

proc addToken(scanner: var Scanner, tokenType: TokenType) =
  scanner.addToken(tokenType, "")

proc scanToken(scanner: var Scanner) =
  let c = scanner.advance()

  case c
  of '(': scanner.addToken(TokenType.LEFT_PAREN)
  of ')': scanner.addToken(TokenType.RIGHT_PAREN)
  of '{': scanner.addToken(TokenType.LEFT_BRACE)
  of '}': scanner.addToken(TokenType.RIGHT_BRACE)
  of ',': scanner.addToken(TokenType.COMMA)
  of '.': scanner.addToken(TokenType.DOT)
  of '-': scanner.addToken(TokenType.MINUS)
  of '+': scanner.addToken(TokenType.PLUS)
  of ';': scanner.addToken(TokenType.SEMICOLON)
  of '*': scanner.addToken(TokenType.STAR)
  else: error(scanner.line, "Unexpected character.")


proc scanTokens*(scanner: var Scanner): seq[Token] =
  while not scanner.isAtEnd:
    scanner.start = scanner.current
    scanner.scanToken()

  scanner.tokens.add(Token(tokenType: TokenType.EOF, lexeme: "", literal: "", line: scanner.line))
  return scanner.tokens
