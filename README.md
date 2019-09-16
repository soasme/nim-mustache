# Nim-mustache

[Mustache](https://mustache.github.io/mustache.1.html) in [Nim](https://nim-lang.org).

Nim-mustache is a Nim implementation of Mustache.
Mustache is a logic-less templating system inspired by ctemplate and et.
Mustache "emphasizes separating logic from presentation: it is impossible to embed application logic in this template language."

## Status

Alpha. This project is WIP. I'll release v0.1.0 before 23 Sep, 2019.

TODO:

- [x] Support Static Text.
- [x] Support Variables.
- [x] Support Sections.
- [x] Support Inverted Sections.
- [x] Support Comments.
- [x] Support Setting Delimiter.
- [ ] Support Partial.
- [ ] Pass mustache spec.
- [ ] Release v0.1.0.
- [ ] Add Docs.
- [ ] Auto Build.

## Getting Started

Nim-mustache requires Nim >= 0.20.

```bash
$ nimble install mustache # not yet available until 23 Sep, 2019
```

## Usage

```nim
# Step 1.
import mustache, tables

# Step 2.
c = Context()
c["i"] = 1
c["f"] = 1.0
c["s"] = "hello world"
c["l"] = @[{"k": "v"}.toTable]
c["t"] = {"k": "v"}.toTable
c["l"] = proc(s: string, c: Context): string = "<b>" & s.render(c) & "</b>"

# Step 3.
let s = """
{{i}} {{f}} {{s}}
{{#l}}
  {{k}}
{{/l}}

{{#t}}
  {{k}}
{{/t}}

{{#l}}
  {{s}}
{{/l}}
"""
echo(s.render(c))
```

## Develop

```
$ nimble build
```

```bash
$ nimble test
```

## References

* [Spec](https://github.com/mustache/spec)
* [Syntax](http://mustache.github.com/mustache.5.html)
