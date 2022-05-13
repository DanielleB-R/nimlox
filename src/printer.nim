import ast, sequtils, strutils, token, value

type
  AstPrinter* = ref object of Visitor
    discard

proc print*(printer: AstPrinter, expr: Expr): string =
  expr.accept(printer).strVal

proc parenthesize(visitor: AstPrinter, name: string, exprs: varargs[
    Expr]): string =
  "(" & name & " " & exprs.mapIt(it.accept(visitor)).join(" ") & ")"

method visitBinary*(visitor: AstPrinter, expr: Binary): Value =
  visitor.parenthesize(expr.operator.lexeme, expr.left, expr.right).stringValue

method visitGrouping*(visitor: AstPrinter, expr: Grouping): Value =
  visitor.parenthesize("group", expr.expression).stringValue

method visitLiteral*(visitor: AstPrinter, expr: Literal): Value =
  ($expr.value).stringValue

method visitUnary*(visitor: AstPrinter, expr: Unary): Value =
  visitor.parenthesize(expr.operator.lexeme, expr.right).stringValue

when isMainModule:
  let
    printer = AstPrinter()
    expression = Binary(
      left: Unary(operator: Token(tokenType: TokenType.MINUS, lexeme: "-",
          literal: NullValue, line: 1), right: Literal(value: numberValue(
          123.0)),
      ),
      operator: Token(tokenType: TokenType.STAR, lexeme: "*",
          literal: NullValue, line: 1),
      right: Grouping(expression: Literal(value: numberValue(45.67)))
    )

  echo printer.print(expression)
