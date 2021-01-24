import unittest, tables

import mustachepkg/values

test "set basic values to context":
  let ctx = newContext()
  ctx["name"] = 1
  check ctx["name"].castBool

  ctx["key"] = "string"
  check ctx["key"].castBool

  ctx["seq"] = @[1,2,3]
  check ctx["seq"].castStr == "[1,2,3]"
  ctx["seq"] = @["a","b","c"]
  check ctx["seq"].castBool
  check ctx["seq"].castStr == "[a,b,c]"

  ctx["table"] = {"a": "b"}.toTable
  check ctx["table"].castBool
  check ctx["table"].castStr == "{a: b}"

  check not ctx["nonExisting"].castBool

