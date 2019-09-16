import strutils, strformat

import ./errors
import ./tokens
import ./values

method render*(token: Token, ctx: Context): string {.base.} = ""

method render*(token: Text, ctx: Context): string =
  token.doc

method render*(token: EscapedTag, ctx: Context): string =
  ctx[token.key.strip].castStr

method render*(token: UnescapedTag, ctx: Context): string =
  ctx[token.key.strip].castStr

proc render*(tokens: seq[Token], ctx: Context): string =
  var stack: seq[Token] = @[]
  for token in tokens:
    if token of SectionOpen:
      stack.add(token)
    elif token of SectionClose:
      var close = SectionClose(token)
      if stack.len == 0:
        raise newException(MustacheError, fmt"early closed: {close.key}")
      var lastOpen = SectionOpen(stack[stack.len-1])
      if close.key.strip != lastOpen.key.strip:
        raise newException(MustacheError,
          fmt"unmatch section: last open: {lastOpen.key}, close: {close.key}")
    else:
      result.add(token.render(ctx))
