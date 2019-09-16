import tables, sequtils, strutils, strformat, os

type
  ValueKind* {.pure.}= enum
    vkInt,
    vkFloat,
    vkString,
    vkBool,
    vkProc,
    vkSeq,
    vkTable

  Value* = object
    case kind*: ValueKind
    of vkInt: vInt*: int
    of vkFloat: vFloat*: float
    of vkString: vString*: string
    of vkBool: vBool*: bool
    of vkProc: vProc*: proc(s: string, c: Context): string {.closure.}
    of vkSeq: vSeq*: seq[Value]
    of vkTable: vTable*: ref Table[string, Value]

  Context* = ref object
    values: Table[string, Value]
    parent: Context
    searchDirs: seq[string]

proc castValue*(value: int): Value =
  Value(kind: vkInt, vInt: value)

proc castValue*(value: float): Value =
  Value(kind: vkFloat, vFloat: value)

proc castValue*(value: string): Value =
  Value(kind: vkString, vString: value)

proc castValue*(value: bool): Value =
  Value(kind: vkBool, vBool: value)

proc castValue*(value: proc(s: string, c: Context) : string): Value =
  Value(kind: vkProc, vProc: value)

proc castValue*[T](value: Table[string, T]): Value =
  let newValue = new(Table[string, Value])
  for k, v in value.pairs:
    newValue[k] = v.castValue
  Value(kind: vkTable, vTable: newValue)

proc castValue*[T](value: seq[T]): Value =
  Value(kind: vkSeq, vSeq: value.map(castValue))

proc `[]=`*(ctx: Context, key: string, value: Value) =
  ctx.values[key] = value

proc `[]=`*[T](ctx: Context, key: string, value: T) =
  ctx.values[key] = value.castValue

proc `[]`*(ctx: Context, key: string): Value =
  if ctx.values.contains(key):
    result = ctx.values[key]
  elif ctx.parent != nil:
    result = ctx.parent[key]
  else:
    result = castValue("")

proc castBool*(value: Value): bool =
  case value.kind
  of vkInt: value.vInt != 0
  of vkFloat: value.vFloat != 0.0
  of vkString: value.vString != ""
  of vkBool: value.vBool
  of vkSeq: value.vSeq.len != 0
  of vkTable: value.vTable.len != 0
  else: true

proc castStr*(value: Value): string =
  case value.kind
  of vkInt: $(value.vInt)
  of vkFloat: $(value.vFloat)
  of vkString: value.vString
  of vkBool: $(value.vBool)
  of vkSeq: "@[]" # TODO
  of vkTable: "{}" # TODO
  else: ""

proc newContext*(searchDirs = @["./"]): Context =
  Context(values: initTable[string,Value](), searchDirs: searchDirs)

proc read*(c: Context, filename: string): string =
  for dir in c.searchDirs:
    let path = fmt"{dir}/{filename}.mustache"
    if existsFile(path):
      return readFile(path)
  if c.parent != nil:
    return c.parent.read(filename)
  else:
    return ""

proc derive*(val: Value, c: Context): Context =
  result = Context(parent: c)
  if val.kind == vkTable:
    for k, val in val.vTable.pairs:
      result[k] = val
