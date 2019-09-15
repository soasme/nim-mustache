import strutils

import ./tokens
import ./values

method render*(token: Token, ctx: Context): string {.base.} = ""

method render*(token: Text, ctx: Context): string =
  token.doc

method render*(token: EscapedTag, ctx: Context): string =
  ctx[token.key.strip].castStr

proc render*(tokens: seq[Token], ctx: Context): string =
  let stack: seq[Token] = @[]
  for token in tokens:
    result.add(token.render(ctx))
