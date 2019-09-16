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

method render*(token: Section, ctx: Context): string =
  "section"

proc render*(tokens: seq[Token], ctx: Context): string =
  var stack: seq[Section] = @[]
  for token in tokens:
    if token of SectionOpen:
      let open = SectionOpen(token)
      stack.add(Section(key: open.key, children: @[]))
    elif token of SectionClose:
      var close = SectionClose(token)
      if stack.len == 0:
        raise newException(MustacheError, fmt"early closed: {close.key}")
      var lastSection = stack[stack.len-1]
      if close.key.strip != lastSection.key:
        raise newException(MustacheError,
          fmt"unmatch section: last open: {lastSection.key}, close: {close.key}")
      discard stack.pop()
      if stack.len == 0:
        result.add(lastSection.render(ctx))
      else:
        stack[stack.len-1].children.add(lastSection)
    elif stack.len != 0:
      stack[stack.len-1].children.add(token)
    else:
      result.add(token.render(ctx))
