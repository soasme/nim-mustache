import strutils, strformat

import ./errors
import ./tokens
import ./values

proc render*(tokens: seq[Token], ctx: Context): string;

method render*(token: Token, ctx: Context): string {.base.} = ""

method render*(token: Text, ctx: Context): string =
  token.doc

method render*(token: EscapedTag, ctx: Context): string =
  ctx[token.key.strip].castStr

method render*(token: UnescapedTag, ctx: Context): string =
  ctx[token.key.strip].castStr

method render*(token: Section, ctx: Context): string =
  let val = ctx[token.key]

  var display = val.castBool
  if token.inverted:
    display = not display

  if not display:
    return ""

  # Lists
  if val.kind == vkSeq:
    for el in val.vSeq:
      var newCtx = el.derive(ctx)
      newCtx["."] = el
      result.add(render(token.children, newCtx))

  # Tables
  elif val.kind == vkTable:
    return render(token.children, val.derive(ctx))

  # TODO: Lambdas

  # Non-empty Values
  else:
    return render(token.children, ctx)

proc render*(tokens: seq[Token], ctx: Context): string =
  var stack: seq[Section] = @[]
  for token in tokens:
    if token of SectionOpen:
      let open = SectionOpen(token)
      stack.add(Section(
        key: open.key,
        inverted: open.inverted,
        children: @[]
      ))

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
