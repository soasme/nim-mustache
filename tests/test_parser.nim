import unittest, strscans, streams, strutils, tables

import mustachepkg/tokens
import mustachepkg/values
import mustachepkg/parser
import mustachepkg/render

test "parse text - normal text":
  check "parse text".render() == "parse text"

test "parse text - unopened tag":
  check "parse text }}".render(newContext()) == "parse text }}"

test "parse text - unbalanced tag":
  check "parse text {{ xyz".render(newContext()) == "parse text {{ xyz"

test "parse tag - escaped":
  let ctx = newContext()
  ctx["key"] = "value"
  for s in @["{{key}}", "{{ key  }}"]:
    check s.render(ctx) == "value"

test "parse comment":
  check "{{!comment}}".render(newContext()) == ""

test "parse unescaped":
  let ctx = newContext()
  ctx["name"] = "&mustache"
  check "{{& name}}".render(ctx) == "&mustache"
  check "{{{ name }}}".render(ctx) == "&mustache"

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

test "render section - never shown":
  check "{{#section}}Never shown{{/section}}".render == ""

test "render section - shown":
  let c = newContext()
  c["section"] = true
  check "{{#section}}Shown{{/section}}".render(c) == "Shown"

test "render section - non-empty lists":
  let s = "{{#repo}}{{name}}{{/repo}}"
  let c = newContext()
  c["repo"] = @[{"name": "Shown."}.toTable, {"name": "Shown Again."}.toTable]
  check s.render(c) == "Shown.Shown Again."

test "render section - non-false values":
  let s = "{{#repo}}{{name}}{{/repo}}"
  let c = newContext()
  c["repo"] = {"name": "Shown."}.toTable
  check s.render(c) == "Shown."

test "render section - .":
  let s = "{{#repo}}{{.}}{{/repo}}"
  let c = newContext()
  c["repo"] = @["Shown.", "Shown Again."]
  check s.render(c) == "Shown.Shown Again."

test "render section - inverted":
  let s = "{{^section}}Shown.{{/section}}"
  let c = newContext()
  let r = s.render(c)
  check r == "Shown."

test "render section - inverted truthy value":
  let s = "{{^section}}Never Shown.{{/section}}"
  let c = newContext()
  c["section"] = true
  check s.render(c) == ""

test "render section - lambda":
  let s = "{{#section}}Shown.{{/section}}"
  let c = newContext()
  c["section"] = proc (s: string, c: Context): string = "Replaced: " & s
  check s.render(c) == "Replaced: Shown."

test "render section - lambda - static":
  let s = "{{#section}}{{k}}{{/section}}"
  let c = newContext()
  c["k"] = "v"
  c["section"] = proc (s: string, c: Context): string = "Replaced: " & s
  check s.render(c) == "Replaced: {{k}}"

test "render section - parent context":
  let s = "{{#section}}{{k}}{{/section}}"
  let c = newContext()
  c["k"] = "Shown"
  c["section"] = true
  check s.render(c) == "Shown"

test "render section - overwrite parent context":
  let s = "{{#section}}{{k}}{{/section}}"
  let c = newContext()
  c["k"] = "Never Shown"
  c["section"] = {"k": "Shown"}.toTable
  check s.render(c) == "Shown"

test "render section - overwrite parent context in list":
  let s = "{{#section}}{{k}}{{/section}}"
  let c = newContext()
  c["k"] = "Shown"
  c["section"] = @[{"v": "Never Shown"}.toTable]
  check s.render(c) == "Shown"

test "render partial":
  let s = "{{>test}}"
  let c = newContext(searchDirs = @["./tests"])
  c["section"] = true
  check s.render(c) == "Shown"

test "scan text stop":
  let delim = Delimiter(open: "{{", close: "}}")
  check "abcde".scanTextStop(0, delim) == "abcde".len
  check "abcde\n\n".scanTextStop(0, delim) == "abcde\n".len
  check "abcde\n\n".scanTextStop(6, delim) == "\n".len
  check "abcde\n\n   {{abc}}".scanTextStop(6, delim) == "\n".len

test "render partial from memory":
  let s = "loaded from: {{>test}}"
  let partials = {
    "test": "in memory"
  }.toTable()
  let c = newContext(partials = partials)
  check s.render(c) == "loaded from: in memory"


test "render partial from multiple sources":
  let s = "loaded from: {{>test}}"
  let partials1 = {
    "test": "in memory 1"
  }.toTable()
  let partials2 = {
    "test": "in memory 2"
  }.toTable()
  let c = newContext()
  c.searchTable(partials1)
  c.searchTable(partials2)
  check s.render(c) == "loaded from: in memory 1"

test "render inheritance - no params":
  let s = "{{<test}}{{/test}}"
  let c = newContext(partials = {"test": "hello world"}.toTable())
  check s.render(c) == "hello world"

test "render inheritance - params":
  let s = "{{<test}}{{/test}}"
  let c = newContext(partials = {"test": "{{$foo}}default{{/foo}}"}.toTable())
  check s.render(c) == "default"

test "render inheritance - override params":
  let s = "{{<test}}{{$foo}}hello world{{/foo}}{{/test}}"
  let c = newContext(partials = {"test": "{{$foo}}default{{/foo}}"}.toTable())
  check s.render(c) == "hello world"
