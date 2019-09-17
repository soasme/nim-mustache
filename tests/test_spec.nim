import json, system, unittest, strformat, os
import mustache

const SPEC_FILES = @[
  "./tests/comments.json",
  "./tests/delimiters.json",
  "./tests/interpolation.json",
  "./tests/inverted.json",
  "./tests/partials.json",
  "./tests/sections.json",
]

for spec_file in SPEC_FILES:
  let jsonData = parseFile(spec_file)
  for spec in jsonData["tests"]:
    let tpl = spec["template"].getStr
    let name = spec["name"].getStr
    let desc = spec["desc"].getStr
    let expected = spec["expected"].getStr
    let data = spec["data"]
    if spec.hasKey("partials"):
      for key, partial in spec["partials"].pairs:
        writeFile(fmt"./tests/{key}.mustache", partial.getStr)
    test(spec_file & " - " & name & " - " & desc):
      let c = newContext(searchDirs = @["./tests"])
      for key, val in data.pairs:
        c[key] = val
      check tpl.render(c) == expected

    if spec.hasKey("partials"):
      for key, partial in spec["partials"].pairs:
        removeFile(fmt"./tests/{key}.mustache")
