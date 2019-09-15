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

test "parse comment":
  let r = "{{!comment}}".parse
  check r.len == 0

test "parse unescaped":
  let r = "{{& name}}".parse
  check r.len == 1
  check r[0] of UnescapedTag
  check UnescapedTag(r[0]).key.strip == "name"

test "parse triple mustache":
  let r = "{{{ name }}}".parse
  check r.len == 1
  check r[0] of UnescapedTag
  check UnescapedTag(r[0]).key.strip == "name"

test "parse section open":
  let r = "{{# start }}".parse
  check r.len == 1
  check r[0] of SectionOpen
  check SectionOpen(r[0]).key.strip == "start"
  check SectionOpen(r[0]).inverted == false

test "parse section open - inverted":
  let r = "{{^ start }}".parse
  check r.len == 1
  check r[0] of SectionOpen
  check SectionOpen(r[0]).key.strip == "start"
  check SectionOpen(r[0]).inverted == true

test "parse section close":
  let r = "{{/section}}".parse
  check r.len == 1
  check r[0] of SectionClose
  check SectionClose(r[0]).key.strip == "section"

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
