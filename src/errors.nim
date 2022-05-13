import token

var hadError*: bool = false

proc report(line: int, where, message: string) =
  # TODO: this should be stderr
  echo("[line " & $line & "] Error" & where & ": " & message)
  hadError = true

proc error*(line: int, message: string) =
  report(line, "", message)

proc error*(token: Token, message: string) =
  if token.tokenType == EOF:
    report(token.line, " at end", message)
  else:
    report(token.line, " at '" & token.lexeme & "'", message)
