# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import tables

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

  ValueKind* {.pure.}= enum
    vkInt,
    vkFloat,
    vkString,
    vkBool,
    vkProc,
    vkSeq,
    vkTable

  Value* = ref object
    case kind*: ValueKind
    of vkInt: vInt: int
    of vkFloat: vFloat: float
    of vkString: vString: string
    of vkBool: vBool: bool
    of vkProc: vProc: proc
    of vkSeq: vSeq: seq[Value]
    of vkTable: vTable: Table[string, Value]


when isMainModule:
  echo("hello world")
