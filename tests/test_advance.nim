import unittest, tables

import mustache

type Stock = object
  name*: string
  price*: int

proc castValue(value: Stock): Value =
  let newValue = new(Table[string, Value])
  result = Value(kind: vkTable, vTable: newValue)
  newValue["name"] = value.name.castValue
  newValue["price"] = value.price.castValue

test "new type":
  let c = newContext()
  c["stock"] = Stock(name: "NIM", price: 100)
  let s = "{{#stock}}{{name}}: {{price}}{{/stock}}"
  check s.render(c) == "NIM: 100"
