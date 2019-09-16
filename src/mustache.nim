# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import tables, sequtils, sugar, strutils, strformat

import mustachepkg/errors
import mustachepkg/tokens
import mustachepkg/parser
import mustachepkg/values
import mustachepkg/render

when isMainModule:
  var c = Context()
  c["i"] = 1
  c["f"] = 1.0
  c["s"] = "hello world"
  c["a"] = @[{"k": "v"}.toTable]
  c["t"] = {"k": "v"}.toTable
  c["l"] = proc(s: string, c: Context): string = "<b>" & s.render(c) & "</b>"

  let s = """
{{i}} {{f}} {{s}}
{{#a}}
  {{k}}
{{/a}}

{{#t}}
  {{k}}
{{/t}}

{{#l}}
  {{s}}
{{/l}}
"""
  echo(s.render(c))

