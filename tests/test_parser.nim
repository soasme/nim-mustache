import unittest

import mustachepkg/tokens
import mustachepkg/parser

test "parse text":
  let r = parse("parse text")
  check r.len == 1
  check r[0] of Text
  check Text(r[0]).doc == "parse text"
