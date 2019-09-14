import strscans, strutils, strformat

import ./tokens
import ./errors

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

proc scanm(s: string, idx: var int, delim: Delimiter, token: var Token): bool =
  ## Scan mustache tokens from a given string `s` starting from `idx`.
  ## It turns s[idx .. new idx] to a token and updates idx to new idx.
  ##
  ## TODO: use scanp parse to Text, Tag, Section, etc.
  idx = s.len
  token = Text(doc: s)
  true

proc parse*(s: string): seq[Token] =
  result = @[]

  var delim = Delimiter(open: "{{", close: "}}")
  var idx = 0
  var token: Token

  while idx < s.len:
    if not scanm(s, idx, delim, token):
      raise newException(MustacheError, fmt"unable to advance at pos: {idx}")
    result.add(token)
