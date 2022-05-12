import token, errors, strutils, tables

const keywords = [
  ("and", TokenType.AND),
  ("class", TokenType.CLASS),
  ("else", TokenType.ELSE),
  ("false", TokenType.FALSE),
  ("for", TokenType.FOR),
  ("fun", TokenType.FUN),
  ("if", TokenType.IF),
  ("nil", TokenType.NIL),
  ("or", TokenType.OR),
  ("print", TokenType.PRINT),
  ("return", TokenType.RETURN),
  ("super", TokenType.SUPER),
  ("this", TokenType.THIS),
  ("true", TokenType.TRUE),
  ("var", TokenType.VAR),
  ("while", TokenType.WHILE),
].toTable

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

proc peek(scanner: var Scanner): char =
  result = if scanner.isAtEnd: '\0'
           else: scanner.source[scanner.current]

proc peekNext(scanner: var Scanner): char =
  result = if scanner.current + 1 >= scanner.source.len: '\0'
           else: scanner.source[scanner.current + 1]

proc match(scanner: var Scanner, expected: char): bool =
  if scanner.isAtEnd: return false
  if scanner.source[scanner.current] != expected: return false

  inc scanner.current
  return true

proc addToken(scanner: var Scanner, tokenType: TokenType, literal: string) =
  let text = scanner.source[scanner.start ..< scanner.current]
  scanner.tokens.add(Token(tokenType: tokenType, lexeme: text, literal: literal,
      line: scanner.line))

proc addToken(scanner: var Scanner, tokenType: TokenType) =
  scanner.addToken(tokenType, "")

proc scanString(scanner: var Scanner) =
  while scanner.peek != '"' and not scanner.isAtEnd:
    if scanner.peek == '\n': inc scanner.line
    discard scanner.advance

  if scanner.isAtEnd:
    error(scanner.line, "Unterminated string.")
    return

  discard scanner.advance

  let value = scanner.source[scanner.start+1 ..< scanner.current-1]
  scanner.addToken(TokenType.STRING, value)

proc number(scanner: var Scanner) =
  while scanner.peek in Digits: discard scanner.advance

  if scanner.peek == '.' and scanner.peekNext in Digits:
    discard scanner.advance

    while scanner.peek in Digits: discard scanner.advance

  # TODO: this will need to be a numeric type
  let value = scanner.source[scanner.start ..< scanner.current]
  scanner.addToken(TokenType.NUMBER, value)

proc identifier(scanner: var Scanner) =
  while scanner.peek in IdentChars: discard scanner.advance

  let text = scanner.source[scanner.start ..< scanner.current]
  scanner.addToken(keywords.getOrDefault(text, TokenType.IDENTIFIER))

proc scanToken(scanner: var Scanner) =
  let c = scanner.advance

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
  of '!': scanner.addToken(if scanner.match('='): TokenType.BANG_EQUAL
                           else: TokenType.BANG)
  of '=': scanner.addToken(if scanner.match('='): TokenType.EQUAL_EQUAL
                           else: TokenType.EQUAL)
  of '<': scanner.addToken(if scanner.match('='): TokenType.LESS_EQUAL
                           else: TokenType.LESS)
  of '>': scanner.addToken(if scanner.match('='): TokenType.GREATER_EQUAL
                           else: TokenType.GREATER)
  of '/':
    if scanner.match('/'):
      while scanner.peek != '\n' and not scanner.isAtEnd: discard scanner.advance
    else:
      scanner.addToken(TokenType.SLASH)
  of ' ', '\r', '\t': discard
  of '\n': inc scanner.line
  of '"': scanner.scanString
  of Digits: scanner.number
  of IdentStartChars: scanner.identifier
  else: error(scanner.line, "Unexpected character.")


proc scanTokens*(scanner: var Scanner): seq[Token] =
  while not scanner.isAtEnd:
    scanner.start = scanner.current
    scanner.scanToken

  scanner.tokens.add(Token(tokenType: TokenType.EOF, lexeme: "", literal: "",
      line: scanner.line))
  return scanner.tokens
