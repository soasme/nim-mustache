import unittest, strscans, streams, strutils

import mustachepkg/tokens
import mustachepkg/values
import mustachepkg/parser
import mustachepkg/render

test "parse text - normal text":
  check "parse text".parse.render(newContext()) == "parse text"

test "parse text - unopened tag":
  check "parse text }}".parse.render(newContext()) == "parse text }}"

test "parse text - unbalanced tag":
  check "parse text {{ xyz".parse.render(newContext()) == "parse text {{ xyz"

test "parse tag - escaped":
  let ctx = newContext()
  ctx["key"] = "value"
  for s in @["{{key}}", "{{ key  }}"]:
    check s.parse.render(ctx) == "value"

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
  check r.len == 2

test "parse partial":
  let s = "{{> key }}"
  let r = parse(s)
  check r.len == 1
  check r[0] of Partial
  check Partial(r[0]).key.strip == "key"

#test "parse set delimiter":
  #let src = @["= <% %> =", "=<% %>="]
  #for s in src:
    #var delim = Delimiter(open: "{{", close: "}}")
    #var idx = 0
    #let r = setDelimiter(s, idx, delim)
    #check r == s.len
    #check delim.open == "<%"
    #check delim.close == "%>"
