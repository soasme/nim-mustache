# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import tables, sequtils, sugar, strutils, strformat

import mustachepkg/submodule

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
    opener*: string
    closer*: string

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

type
  ValueKind* {.pure.}= enum
    vkInt,
    vkFloat,
    vkString,
    vkBool,
    vkProc,
    vkSeq,
    vkTable

  Value* = object
    case kind*: ValueKind
    of vkInt: vInt: int
    of vkFloat: vFloat: float
    of vkString: vString: string
    of vkBool: vBool: bool
    of vkProc: vProc: proc()
    of vkSeq: vSeq: seq[Value]
    of vkTable: vTable: ref Table[string, Value]

  Context* = ref object
    values: Table[string, Value]

proc castValue*(value: int): Value =
  Value(kind: vkInt, vInt: value)

proc castValue*(value: float): Value =
  Value(kind: vkFloat, vFloat: value)

proc castValue*(value: string): Value =
  Value(kind: vkString, vString: value)

proc castValue*(value: bool): Value =
  Value(kind: vkBool, vBool: value)

proc castValue*[T](value: Table[string, T]): Value =
  let newValue = new(Table[string, Value])
  for k, v in value.pairs:
    newValue[k] = v.castValue
  Value(kind: vkTable, vTable: newValue)

proc castValue*[T](value: seq[T]): Value =
  Value(kind: vkSeq, vSeq: value.map(castValue))

proc `[]=`*[T](ctx: Context, key: string, value: T) =
  ## Combine the key with a value within the given ctx.
  ## Example:
  ##
  ##   ctx["name"] = 1
  ##   ctx["name"] = "string"
  ##   ctx["name"] = @[1,2,3]
  ctx.values[key] = value.castValue

proc `[]`*(ctx: Context, key: string): Value =
  if ctx.values.contains(key):
    result = ctx.values[key]
  else:
    result = castValue("")

proc castBool*(value: Value): bool =
  case value.kind
  of vkInt: value.vInt != 0
  of vkFloat: value.vFloat != 0.0
  of vkString: value.vString != ""
  of vkBool: value.vBool
  of vkSeq: value.vSeq.len != 0
  of vkTable: value.vTable.len != 0
  else: true

method `$`(token: Token): string {.base.} = "<token>"

method `$`(token: Text): string = fmt"<text ""{token.doc}"">"

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
