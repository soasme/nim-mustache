import unittest, strscans, streams, strutils

import mustachepkg/tokens
import mustachepkg/parser

test "parse text - normal text":
  let r = parse("parse text")
  check r.len == 1
  check r[0] of Text
  check Text(r[0]).doc == "parse text"

test "parse text - unopened tag":
  let r = parse("parse text }}")
  check r.len == 1
  check r[0] of Text
  check Text(r[0]).doc == "parse text }}"

test "parse text - unbalanced tag":
  let r = parse("parse text {{ xyz")
  check r.len == 3
  check r[0] of Text
  check Text(r[0]).doc == "parse text "
  check r[1] of Text
  check Text(r[1]).doc == "{"
  check r[2] of Text
  check Text(r[2]).doc == "{ xyz"

test "parse tag - unescaped":
  for s in @["{{key}}", "{{ key  }}"]:
    let r = parse(s)
    check r.len == 1
    check r[0] of EscapedTag
    check EscapedTag(r[0]).key.strip == "key"

test "parse tag key":
  var token: string
  var idx = 0
  let r = "abcde }}".scanTagKey(idx, Delimiter(close: "}}"), token)
  check token == "abcde "
  check r == 6

test "parse set elimiter - changed":
  let s = "{{=<% %>=}}<% key %>"
  let r = parse(s)
  echo(r)
  check r.len == 2

#test "parse set delimiter":
  #let src = @["= <% %> =", "=<% %>="]
  #for s in src:
    #var delim = Delimiter(open: "{{", close: "}}")
    #var idx = 0
    #let r = setDelimiter(s, idx, delim)
    #check r == s.len
    #check delim.open == "<%"
    #check delim.close == "%>"

#test "parse partial":
  #let s = "> key "
  #var idx = 0
  #var token: Token
  #let r = s.scanPartial(idx, token)
  #check r == s.len
  #check token != nil
  #check token of Partial
  #check Partial(token).key == "key"
