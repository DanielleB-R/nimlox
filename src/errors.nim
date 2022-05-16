import token

var
  hadError*: bool = false
  hadRuntimeError*: bool = false

type
  RuntimeError* = object of CatchableError
    token*: Token

proc newRuntimeError*(token: Token, message: string): ref RuntimeError =
  (ref RuntimeError)(token: token, msg: message, parent: nil)

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

proc runtimeError*(token: Token, message: string) =
  echo(message & "\n[line " & $token.line & "]")
  hadRuntimeError = true
