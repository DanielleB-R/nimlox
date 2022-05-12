var hadError*: bool = false

proc report(line: int, where, message: string) =
  # TODO: this should be stderr
  echo("[line " & $line & "] Error" & where & ": " & message)

proc error*(line: int, message: string) =
  report(line, "", message)
