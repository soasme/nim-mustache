import tables, sequtils, strutils, strformat, os, json

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
    of vkInt: vInt*: BiggestInt
    of vkFloat: vFloat*: float
    of vkString: vString*: string
    of vkBool: vBool*: bool
    of vkProc: vProc*: proc(s: string, c: Context): string {.closure.}
    of vkSeq: vSeq*: seq[Value]
    of vkTable: vTable*: ref Table[string, Value]

  LoaderKind* {.pure.} = enum
    lkDir,
    lkTable

  Loader* = object
    case kind*: LoaderKind
    of lkDir: searchDirs*: seq[string]
    of lkTable: table*: Table[string, string]

  Context* = ref object
    values: Table[string, Value]
    parent: Context
    loaders: seq[Loader]

proc derive*(val: Value, c: Context): Context;

proc loadPartial*(loader: Loader, filename: string): (bool, string) =
  case loader.kind
  of lkDir:
    for dir in loader.searchDirs:
      let path = fmt"{dir}/{filename}.mustache"
      if existsFile(path):
        return (true, readFile(path))
  of lkTable:
    if loader.table.hasKey(filename):
      return (true, loader.table[filename])

  return (false, "")

proc newContext*(searchDirs = @["./"], partials = initTable[string, string](), values = initTable[string,Value]()): Context =
  var loaders: seq[Loader]

  if searchDirs.len != 0:
    loaders.add(Loader(kind: lkDir, searchDirs: searchDirs))

  if partials.len != 0:
    loaders.add(Loader(kind: lkTable, table: partials))

  Context(values: values, loaders: loaders)

proc searchDirs*(c: Context, dirs: seq[string]) =
  c.loaders.add(Loader(kind: lkDir, searchDirs: dirs))

proc searchTable*(c: Context, table: Table[string, string]) =
  c.loaders.add(Loader(kind: lkTable, table: table))

proc read*(c: Context, filename: string): string =
  for loader in c.loaders:
    let (found, ret) = loader.loadPartial(filename)
    if found:
      return ret

  if c.parent != nil:
    return c.parent.read(filename)
  else:
    return ""

proc castValue*(value: int): Value =
  Value(kind: vkInt, vInt: cast[BiggestInt](value))

proc castValue*(value: BiggestInt): Value =
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

proc castValue*(value: Value): Value = value

proc castValue*(value: JsonNode): Value =
  case value.kind
  of JObject:
    let vTable = new(Table[string, Value])
    for key, val in value.pairs:
      vTable[key] = val.castValue
    result = Value(kind: vkTable, vTable: vTable)
  of JArray:
    var vSeq: seq[Value] = @[]
    for elem in value.elems:
      vSeq.add(elem.castValue)
    result = Value(kind: vkSeq, vSeq: vSeq)
  of JString:
    result = value.str.castValue
  of JBool:
    result = value.bval.castValue
  of JFloat:
    result = value.fnum.castValue
  of JInt:
    result = value.num.castValue
  of JNull:
    result = castValue("")

proc lookup(ctx: Context, key: string): Value =
  if ctx.values.contains(key):
    return ctx.values[key]

  if key.contains("."):
    var subctx = ctx
    var found = true
    for subkey in key.split("."):
      if result.kind == vkSeq:
        try:
          let subidx = subkey.parseInt
          result = result.vSeq[subidx]
          subctx = result.derive(subctx)
          continue
        except:
          found = false
          break

      if not subctx.values.contains(subkey):
        found = false
        break

      result = subctx.values[subkey]
      subctx = result.derive(subctx)

    if found:
      return result

  if ctx.parent == nil:
    return castValue("")

  return ctx.parent.lookup(key)


proc `[]`*(ctx: Context, key: string): Value =
  return ctx.lookup(key)

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
  of vkSeq:
    var buf: seq[string] = @[]
    for el in value.vSeq:
      buf.add(castStr(el))
    "[" & buf.join(",") & "]"
  of vkTable:
    var buf: seq[string] = @[]
    for key, val in value.vTable.pairs:
      buf.add(fmt"{key}: {val.castStr}")
    "{" & buf.join(",") & "}"
  else: ""

proc `[]=`*(ctx: Context, key: string, value: Value) =
  ctx.values[key] = value

proc `[]=`*[T](ctx: Context, key: string, value: T) =
  ctx.values[key] = value.castValue

proc derive*(val: Value, c: Context): Context =
  result = Context(parent: c)
  if val.kind == vkTable:
    for k, val in val.vTable.pairs:
      result[k] = val

proc toValues*(data: JsonNode): Table[string, Value] =
  assert data.kind == JObject, "JsonNode must be a JObject"
  for key, val in data.pairs:
    result[key] = val.castValue
