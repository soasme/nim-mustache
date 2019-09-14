# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import tables, sequtils, sugar

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
    doc*: string
    pos*: int
    size*: int

  Text* = ref object of Token

  EscapedTag* = ref object of Token
    name*: string
    tag*: string

  UnescapedTag* = ref object of Token
    name*: string
    tag*: string

  Section* = ref object of Token
    name*: string
    tag*: string
    inverted*: bool
    children*: seq[Token]
    delimiter*: Delimiter

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

proc asValue*(value: int): Value =
  Value(kind: vkInt, vInt: value)

proc asValue*(value: float): Value =
  Value(kind: vkFloat, vFloat: value)

proc asValue*(value: string): Value =
  Value(kind: vkString, vString: value)

proc asValue*(value: bool): Value =
  Value(kind: vkBool, vBool: value)

proc asValue*[T](value: Table[string, T]): Value =
  let newValue = new(Table[string, Value])
  for k, v in value.pairs:
    newValue[k] = v.asValue
  Value(kind: vkTable, vTable: newValue)

proc asValue*[T](value: seq[T]): Value =
  Value(kind: vkSeq, vSeq: value.map(asValue))

proc `[]=`*[T](ctx: Context, key: string, value: T) =
  ## Combine the key with a value within the given ctx.
  ## Example:
  ##
  ##   ctx["name"] = 1
  ##   ctx["name"] = "string"
  ##   ctx["name"] = @[1,2,3]
  ctx.values[key] = value.asValue

when isMainModule:
  let ctx = Context(values: initTable[string,Value]())
  ctx["name"] = 1
  ctx["key"] = "string"
  ctx["seq"] = @[1,2,3]
  ctx["seq"] = @["a","b","c"]
  ctx["table"] = {"a": "b"}.toTable
  echo("hello world")
