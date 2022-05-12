import errors as e
import scanner
import token

proc run(source: string) =
  var scanner = newScanner(source)
  let tokens = scanner.scanTokens

  for token in tokens:
    echo(token)

proc runFile(path: string) =
  run(readFile path)

  # TODO: Return non-zero status code here on error

proc runPrompt() =
  var line: string

  while true:
    stdout.write("> ")
    if not stdin.readLine(line):
      break
    run(line)
    e.hadError = false

when isMainModule:
  import os

  case paramCount()
  of 0: runPrompt()
  of 1: runFile(paramStr(1))
  else: echo("Usage: nimlox [script]")
