import strutils, strformat, sequtils, sugar, tables

import ./errors
import ./tokens
import ./values
import ./parser

proc escape(s: string): string = s.multiReplace([
    ("&", "&amp;"),
    ("\"", "&quot;"),
    ("<", "&lt;"),
    (">", "&gt;"),
  ])

method render*(token: Token, ctx: Context): string {.base, locks: "unknown".} = ""

proc toAst*(tokens: seq[Token]): seq[Token] =
  var stack: seq[SectionOpen] = @[]
  for token in tokens:
    if token of SectionOpen:
      let open = SectionOpen(token)
      stack.add(open)

    elif token of SectionClose:
      var close = SectionClose(token)
      if stack.len == 0:
        raise newException(MustacheError, fmt"early closed: {close.key}.")

      var open = stack[stack.len-1]
      if close.key.strip != open.key:
        raise newException(MustacheError,
          fmt"unmatch section: last open: {open.key}, close: {close.key}")

      discard stack.pop()

      var astToken: Token
      if open.parent:
        let astChildren = open.children.filter(x => x of Section and Section(x).`block`)
        astToken = Parent(key: open.key, children: astChildren)
      else:
        astToken = Section(key: open.key, inverted: open.inverted,
          children: open.children, `block`: open.`block`)

      if stack.len == 0:
        result.add(astToken)
      else:
        stack[stack.len-1].children.add(astToken)

    elif stack.len != 0:
      stack[stack.len-1].children.add(token)

    else:
      result.add(token)

proc render*(tokens: seq[Token], ctx: Context): string =
  for token in tokens.toAst:
    result.add(token.render(ctx))

proc render*(s: string, ctx: Context = newContext()): string =
  s.parse.render(ctx)

method render*(token: Text, ctx: Context): string {.locks: "unknown".}=
  token.doc

method render*(token: EscapedTag, ctx: Context): string =
  ctx[token.key].castStr.escape

method render*(token: UnescapedTag, ctx: Context): string =
  ctx[token.key].castStr

proc substituteBlocks(ctx: Context, token: Parent, blocks: var Table[string, seq[Token]]): seq[Token]

proc recuriveSubstituteToken(ctx: Context, token: Token,
  blocks: var Table[string, seq[Token]]): seq[Token] =
  if token of Parent:
    substituteBlocks(ctx, Parent(token), blocks)
  else:
    @[token]

proc substituteBlocks(ctx: Context, token: Parent, blocks: var Table[string, seq[Token]]): seq[Token] =
  for `block` in token.children:
    let section = Section(`block`)
    if not (section.key in blocks):
      blocks[section.key] = section.children

  let s = ctx.read(token.key)
  for child in s.parse.toAst:
    if child of Section and Section(child).`block`:
      let section = Section(child)

      var sbst = if section.key in blocks:
        blocks[section.key]
      else:
        section.children

      for x in sbst:
        result = concat(result, recuriveSubstituteToken(ctx, x, blocks))
    else:
        result = concat(result, recuriveSubstituteToken(ctx, child, blocks))

method render*(token: Parent, ctx: Context): string =
  var blocks = initTable[string, seq[Token]]()
  let children = substituteBlocks(ctx, token, blocks)
  return children.render(ctx)

method render*(token: Partial, ctx: Context): string =
  let s = ctx.read(token.key)

  var lns: seq[string] = @[]
  for ln in s.splitLines(keepEol=true):
    if ln != "":
      lns.add(" ".repeat(token.indent) & ln)
  result = lns.join("").render(ctx)

method render*(token: Section, ctx: Context): string =
  let val = ctx[token.key]
  let truthy = val.castBool

  if token.`block`:
    return token.children.render(ctx)

  # Inverted
  if token.inverted:
    if truthy:
      return ""
    else:
      return render(token.children, ctx)

  if not truthy:
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

  # Lambdas handles static strings.
  elif val.kind == vkProc:
    let src = token.children.map(
      proc(s: Token): string = s.src
    ).join("")
    return val.vProc(src, ctx)

  # Non-empty Values
  else:
    var newCtx = {".": val}.toTable.castValue.derive(ctx)
    return render(token.children, newCtx)
