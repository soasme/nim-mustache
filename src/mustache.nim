# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import tables, sequtils, sugar, strutils, strformat

import mustachepkg/values

type
  MustacheErrorKind* {.pure.}= enum
    GeneralError,
    BadClosingTag,
    UnclosedTag,
    UnclosedSection,
    UnbalancedUnescapeTag,
    EmptyTag,
    EarlySectionClose,
    MissingSetDelimeterClosingTag,
    InvalidSetDelimeterSyntax

  MustacheError* = ref object of Exception
    message: string
    case kind*: MustacheErrorKind
    of BadClosingTag:
      expect, actual: string
    of UnclosedSection, EarlySectionClose:
      key: string
    else: discard

  Delimiter* = ref object
    open*: string
    close*: string

  Token* = ref object of RootObj
    pos*: int
    size*: int

  Text* = ref object of Token
    doc*: string

  EscapedTag* = ref object of Token
    name*: string
    tag*: string

  UnescapedTag* = ref object of Token
    name*: string
    tag*: string

  SectionOpen* = ref object of Token
    name*: string
    tag*: string
    inverted*: bool
    delimiter*: Delimiter

  SectionClose* = ref object of Token

  Partial* = ref object of Token

  SetDelimiter* = ref object of Token
    delimiter*: Delimiter

  ParseState* {.pure.} = enum
    ScanningVerbatim,
    ScanningTag,
    OpeningTag,
    ClosingTag

  State* = ref object
    state*: ParseState
    delimiter*: Delimiter
    root*: Token

method `$`(token: Token): string {.base.} = "<token>"

method `$`(token: Text): string = fmt"<text ""{token.doc}"">"

type
  LexState* {.pure.} = enum
    lsText,
    lsTag,
    lsEof

proc peeks*(s: string, start: int): string = s[start ..< s.len]

proc openDelimiter*(s: string): int =
  ## Open delimiter eats string `s` for up to 2 chars if s starts with `{{`.
  ##
  ## Example:
  ##
  ##   echo("{{ abc }}".openDelimiter) # 2
  if s.startsWith("{{"): 2 else: 0

proc closeDelimiter*(s: string): int =
  ## Close delimiter eats string `s` for up to 2 chars if s starts with `}}`.
  ##
  ## Example:
  ##
  ##   echo("}}".closeDelimiter) # 2
  if s.startsWith("}}"): 2 else: 0

proc text*(s: string, delimiter: Delimiter): int =
  ## Anything that does not conflict with open or close counts as text.
  ## Text eats string `s` until an open or close delimiter is detected.
  ##
  ## Example:
  ##
  ##   echo("text {{ abc }}".text(delim)) # 5
  result = 0
  var idx = 0
  while idx < s.len:
    if s.peeks(idx).openDelimiter != 0 or s.peeks(idx).closeDelimiter != 0:
      break
    result += 1
    idx += 1

proc parse*(tpl: string): seq[Token] =
  result = @[]
  result.add(Text(doc: tpl))

when isMainModule:
  let ctx = Context(values: initTable[string,Value]())
  ctx["name"] = 1
  ctx["key"] = "string"
  ctx["seq"] = @[1,2,3]
  ctx["seq"] = @["a","b","c"]
  ctx["table"] = {"a": "b"}.toTable
  echo("hello world".parse)
  echo("{{ abc }}".openDelimiter)
  echo("}}".closeDelimiter)
  let delim = Delimiter(open: "{{", close: "}}")
  echo("text {{ abc }}".text(delim))

