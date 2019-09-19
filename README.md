# Nim-mustache

[Mustache](https://mustache.github.io/mustache.1.html) in [Nim](https://nim-lang.org).

Nim-mustache is a Nim implementation of Mustache.
Mustache is a logic-less templating system inspired by ctemplate and et.
Mustache "emphasizes separating logic from presentation: it is impossible to embed application logic in this template language."

![Build Status](https://travis-ci.org/soasme/nim-mustache.svg?branch=master)

## Features

- ✨ Support Static Text.
- ✨ Support Variables.
- ✨ Support Sections.
- ✨ Support Inverted Sections.
- ✨ Support Comments.
- ✨ Support Setting Delimiter.
- ✨ Support Partial.
- ✨ Passed all mustache specs.

## Getting Started

Nim-mustache requires Nim >= 0.20.

```bash
$ nimble install mustache
```

## Usage

```nim
# Step 1.
import mustache, tables

# Step 2.
var c = newContext()
c["i"] = 1
c["f"] = 1.0
c["s"] = "hello world"
c["a"] = @[{"k": "v"}.toTable]
c["t"] = {"k": "v"}.toTable
c["l"] = proc(s: string, c: Context): string = "<b>" & s.render(c) & "</b>"

# Step 3.
let s = """
{{i}} {{f}} {{s}}
{{#a}}
  {{k}}
{{/a}}

{{#t}}
  {{k}}
{{/t}}

{{#l}}
  {{s}}
{{/l}}
"""
echo(s.render(c))
```

## Advanced Usage

### Set Arbitrary Objects in Context.

## Develop

Build the binary.

```
$ nimble build
```

Run test cases.

```bash
$ nimble test
```

## Changelog

* v0.1.0, 19 Sep 2019, initial release.

## Alternatives

* [moustachu](https://github.com/fenekku/moustachu). Moustachu doesn't implement some mustache features, such as lambda, set delimiters, while Nim-mustache supports all mustache features.

## References

* [Spec](https://github.com/mustache/spec)
* [Syntax](http://mustache.github.com/mustache.5.html)
