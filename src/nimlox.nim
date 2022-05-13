import errors as e
import parser
import printer
import scanner

proc run(source: string) =
  var scanner = newScanner(source)
  let tokens = scanner.scanTokens
  var parser = newParser(tokens)
  let expression = parser.parse()

  if e.hadError:
    return

  echo AstPrinter().print(expression)

proc runFile(path: string) =
  run(readFile path)

  if e.hadError:
    quit(65)

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
  else:
    echo("Usage: nimlox [script]")
    quit(64)
