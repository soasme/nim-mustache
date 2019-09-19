import unittest, tables

import mustache

type Stock = object
  price*: int

method castValue(value: Stock): Value =
  let newValue = new(Table[string, Value])
  result = Value(kind: vkTable, vTable: newValue)
  newValue["price"] = value.price.castValue

test "new type":
  let c = newContext()
  c["stock"] = Stock(price: 100)
  let s = "{{#stock}}{{price}}{{/stock}}"
  check s.render(c) == "100"
