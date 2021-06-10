import tables, sequtils, strutils, strformat, os, json

type
  ValueKind* {.pure.}= enum
    vkInt,
    vkFloat32,
    vkFloat64,
    vkString,
    vkBool,
    vkProc,
    vkSeq,
    vkTable

  Value* = object
    case kind*: ValueKind
    of vkInt: vInt*: BiggestInt
    of vkFloat32: vFloat32*: float
    of vkFloat64: vFloat64*: float
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

proc castValue*(value: int8): Value =
  Value(kind: vkInt, vInt: cast[BiggestInt](value))

proc castValue*(value: int16): Value =
  Value(kind: vkInt, vInt: cast[BiggestInt](value))

proc castValue*(value: int32): Value =
  Value(kind: vkInt, vInt: cast[BiggestInt](value))

proc castValue*(value: int64): Value =
  Value(kind: vkInt, vInt: value)

proc castValue*(value: float32): Value =
  Value(kind: vkFloat32, vFloat32: value)

proc castValue*(value: float64): Value =
  Value(kind: vkFloat64, vFloat64: value)

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

proc `[]=`*(ctx: Context, key: string, value: Value) =
  ctx.values[key] = value

proc `[]=`*[T](ctx: Context, key: string, value: T) =
  ctx.values[key] = value.castValue

proc lookupCtx(ctx: Context, key: string): Context =
  result = ctx
  while result != nil:
    if result.values.contains(key):
      return result
    result = result.parent

proc lookup(ctx: Context, key: string): Value =
  if ctx.values.contains(key):
    return ctx.values[key]

  try:
    let subidx = key.parseInt
    if ctx.values.contains(".") and ctx.values["."].kind == vkSeq:
      return ctx.values["."].vSeq[subidx]
  except:
    discard

  let dotidx = key.find(".")
  if dotidx == -1:
    if ctx.parent == nil:
      return castValue("")
    return ctx.parent.lookup(key)

  let firstKey = key[0..<dotidx]
  let remainingKeys = key[dotidx+1..<key.len]
  let firstCtx = lookupCtx(ctx, firstKey)

  if firstCtx == nil:
    return castValue("")

  if not firstCtx.values.contains(firstKey):
    return castValue("")

  let firstValue = firstCtx.values[firstKey]

  var newCtx = Context(parent: nil)
  newCtx["."] = firstValue

  return lookup(firstValue.derive(newCtx), remainingKeys)

proc `[]`*(ctx: Context, key: string): Value =
  return ctx.lookup(key)

proc castBool*(value: Value): bool =
  case value.kind
  of vkInt: value.vInt != 0
  of vkFloat32: value.vFloat32 != 0.0
  of vkFloat64: value.vFloat64 != 0.0
  of vkString: value.vString != ""
  of vkBool: value.vBool
  of vkSeq: value.vSeq.len != 0
  of vkTable: value.vTable.len != 0
  else: true

proc castStr*(value: Value): string =
  case value.kind
  of vkInt: $(value.vInt)
  of vkFloat32: $(value.vFloat32)
  of vkFloat64: $(value.vFloat64)
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

proc derive*(val: Value, c: Context): Context =
  result = Context(parent: c)
  if val.kind == vkTable:
    for k, val in val.vTable.pairs:
      result[k] = val

proc toValues*(data: JsonNode): Table[string, Value] =
  case data.kind:
  of JObject:
    for key, val in data.pairs:
      result[key] = val.castValue
  else:
    result["."] = data.castValue
