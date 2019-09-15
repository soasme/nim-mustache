import strscans, strutils, strformat, parseutils, streams

import ./tokens
import ./errors

proc peeks*(s: string, start: int): string = s[start ..< s.len]

#proc delimiter*(s: string, delim: string): int =
  ### Delimiter eats string `s` for up to N chars if s starts with
  ### the given delim, which has the length of N.
  #if s.startsWith(delim): delim.len else: 0

proc scanText*(s: string, idx: var int, delim: Delimiter, token: var Token): int =
  ## Anything that does not conflict with open or close counts as text.
  ## Text eats string `s` until an open or close delimiter is detected.
  var doc: string
  result = s.parseUntil(doc, delim.open, start=idx)
  if result != 0:
    token = Text(doc: doc)
    idx += result

proc scanTagKey*(s: string, idx: int, delim: Delimiter, token: var string): int =
  s.parseUntil(token, delim.close, start=idx)

proc setDelimiter*(s: string, idx: var int, delim: var Delimiter): int =
  var open: string
  var close: string
  let start = idx

  if scanp(
    s, idx,
    (
      '=',                            # starts from a single char =
      *{' ', '\t'},
      +(~{' '} -> open.add($_)),      # next non-spaces become a open
      +{' ', '\t'},
      +(~{' ', '='} -> close.add($_)),# next non-spaces become a close
      *{' ', '\t'},
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

proc scanTagOpen*(s: string, idx: int, delim: Delimiter): int =
  if s.peeks(idx).startsWith(delim.open): delim.open.len else: 0

proc scanTagClose*(s: string, idx: int, delim: Delimiter): int =
  if s.peeks(idx).startsWith(delim.close): delim.close.len else: 0

proc scanTag*(s: string, idx: var int, delim: var Delimiter, token :var Token): int =
  let start = idx
  let opener = delim.open
  let closer = delim.close
  var key: string

  if not scanp(
    s, idx,
    (
      scanTagOpen($input, $index, delim),
      *{' ', '\t'},
      scanTagKey($input, $index, delim, key),
      *{' ', '\t'},
      scanTagClose($input, $index, delim),
    )
  ):
    idx = start
    return 0

  token = EscapedTag(key: key)
  return idx-start

proc scanm(s: string, idx: var int, delim: var Delimiter, token: var Token): bool =
  ## Scan mustache tokens from a given string `s` starting from `idx`.
  ## It turns s[idx .. new idx] to a token and then updates idx to new idx.
  ##
  ## TODO: use scanp parse to Text, Tag, Section, etc.
  if s.scanTag(idx, delim, token) != 0:
    return true
  return s.scanText(idx, delim, token) != 0

proc parse*(s: string): seq[Token] =
  result = @[]

  var delim = Delimiter(open: "{{", close: "}}")
  var idx = 0
  var token: Token

  while idx < s.len:
    if scanm(s, idx, delim, token):
      result.add(token)
    else:
      # if no mustache rule is matched, it eats 1 char as a Text at a time.
      result.add(Text(doc: fmt"{s[idx]}"))
      idx += 1
