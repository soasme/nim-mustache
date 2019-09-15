import strscans, strutils, strformat

import ./tokens
import ./errors

proc peeks*(s: string, start: int): string = s[start ..< s.len]

proc delimiter*(s: string, delim: string): int =
  ## Delimiter eats string `s` for up to N chars if s starts with
  ## the given delim, which has the length of N.
  if s.startsWith(delim): delim.len else: 0

proc text*(s: string, delim: Delimiter): int =
  ## Anything that does not conflict with open or close counts as text.
  ## Text eats string `s` until an open or close delimiter is detected.
  result = 0
  var idx = 0
  while idx < s.len:
    if s.peeks(idx).delimiter(delim.open) != 0:
      break
    if s.peeks(idx).delimiter(delim.close) != 0:
      break
    result += 1
    idx += 1

proc setDelimiter*(s: string, idx: var int, delim: var Delimiter): int =
  var open: string
  var close: string
  let start = idx

  if scanp(
    s, idx,
    (
      '=',                            # starts from a single char =
      +(~{' '} -> open.add($_)),      # next non-spaces become a open
      +{' ', '\t'},                   # some spaces become a separator
      +(~{' ', '='} -> close.add($_)),# next non-spaces become a close
      '=',                            # ends at a single char =
    )
  ):
    delim = Delimiter(open: open, close: close)
    result = idx - start
  else:
    result = start

proc partial*(s: string, idx: var int, token: var Token): int =
  var key: string
  let start = idx

  if scanp(
    s, idx,
    (
      '>',
      *{' ', '\t'},
      +(~{' ', '}'} -> key.add($_)),
      *{' ', '\t'},
    )
  ):
    token = Partial(key: key)
    result = idx - start
  else:
    result = start


proc scanm(s: string, idx: var int, delim: Delimiter, token: var Token): bool =
  ## Scan mustache tokens from a given string `s` starting from `idx`.
  ## It turns s[idx .. new idx] to a token and then updates idx to new idx.
  ##
  ## TODO: use scanp parse to Text, Tag, Section, etc.
  var size = 0

  size = s.text(delim)
  if size != 0:
    token = Text(doc: s[idx ..< idx+size])
    idx += size
    return true

  false

proc parse*(s: string): seq[Token] =
  result = @[]

  var delim = Delimiter(open: "{{", close: "}}")
  var idx = 0
  var token: Token

  while idx < s.len:
    if not scanm(s, idx, delim, token):
      raise newException(MustacheError, fmt"unable to advance at pos: {idx}")
    result.add(token)
