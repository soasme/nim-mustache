# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

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
    opener: string
    closer: string

  Token* = ref object of RootObj

  Text* = ref object of Token
  EscapedTag* = ref object of Token
  UnescapedTag* = ref object of Token
  Section* = ref object of Token
  Partial* = ref object of Token
  SetDelimiter* = ref object of Token

  State* = ref object
    delimiter: Delimiter

when isMainModule:
  echo("hello world")
