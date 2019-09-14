# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import tables, sequtils, sugar, strutils, strformat

import mustachepkg/errors
import mustachepkg/tokens
import mustachepkg/parser
import mustachepkg/values

when isMainModule:
  #echo("hello world".parse)
  echo("{{ abc }}".openDelimiter)
  echo("}}".closeDelimiter)
  #let delim = Delimiter(open: "{{", close: "}}")
  #echo("text {{ abc }}".text(delim))
