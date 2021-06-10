import unittest, tables

import mustachepkg/values

test "set basic values to context":
  let ctx = newContext()
  ctx["name"] = 1
  check ctx["name"].castBool

  ctx["key"] = "string"
  check ctx["key"].castBool

  ctx["f32"] = float32(0.0)
  check ctx["f32"].castStr == "0.0"

  ctx["f32seq"] = @[0'f32, 1'f32]
  check ctx["f32seq"].castStr == "[0.0,1.0]"

  ctx["f64"] = float64(0.0)
  check ctx["f64"].castStr == "0.0"

  ctx["f64seq"] = @[0'f64, 1'f64]
  check ctx["f64seq"].castStr == "[0.0,1.0]"

  ctx["float"] = 0.0
  check ctx["float"].castStr == "0.0"

  ctx["floatseq"] = @[0.0, 1.0]
  check ctx["floatseq"].castStr == "[0.0,1.0]"

  ctx["i8"] = 0'i8
  check ctx["i8"].castStr == "0"

  ctx["i16"] = 0'i16
  check ctx["i16"].castStr == "0"

  ctx["i32"] = 0'i32
  check ctx["i32"].castStr == "0"

  ctx["i64"] = 0'i64
  check ctx["i64"].castStr == "0"

  ctx["int"] = 0
  check ctx["int"].castStr == "0"

  ctx["seq"] = @[1,2,3]
  check ctx["seq"].castStr == "[1,2,3]"
  check ctx["seq.0"].castStr == "1"
  check ctx["seq.0.1"].castStr == ""
  ctx["seq"] = @["a","b","c"]
  check ctx["seq"].castBool
  check ctx["seq"].castStr == "[a,b,c]"
  check ctx["seq.0"].castStr == "a"

  ctx["table"] = {"a": "b"}.toTable
  check ctx["table"].castBool
  check ctx["table"].castStr == "{a: b}"

  check not ctx["nonExisting"].castBool

