type
  TokenType* = enum
    LEFT_PAREN
    RIGHT_PAREN
    LEFT_BRACE
    RIGHT_BRACE
    COMMA
    DOT
    MINUS
    PLUS
    SEMICOLON
    SLASH
    STAR

    BANG
    BANG_EQUAL
    EQUAL
    EQUAL_EQUAL
    GREATER
    GREATER_EQUAL
    LESS
    LESS_EQUAL

    IDENTIFIER
    STRING
    NUMBER

    AND
    CLASS
    ELSE
    FALSE
    FUN
    FOR
    IF
    NIL
    OR
    PRINT
    RETURN
    SUPER
    THIS
    TRUE
    VAR
    WHILE

    EOF

  Token* = object
    tokenType*: TokenType
    lexeme*: string
    # TODO: I'll need to make a discriminated union for this
    literal*: string
    line*: int

proc `$`*(token: Token): string =
  return $token.tokenType & " " & token.lexeme & " " & token.literal
