import std/parseutils
import std/strformat
import std/strutils
import std/strscans
import std/sugar

## Converts a function (in text form) from the javascript core header into a nim proc.
## This isn't 100% perfect so some manual changes are needed



const jsTypes = [ # Keep list of types that we can link to
  "JSStruct",
  "JSPtr",
  "JSContextGroupRef",
  "JSGlobalContextRef",
  "JSClassRef",
  "JSPropertyNameArrayRef",
  "JSPropertyNameAccumulatorRef",
  "JSTypedArrayBytesDeallocator",
  "JSContextRef",
  "JSValueRef",
  "JSObjectRef",
  "JSStringRef",
  "JSType",
  "JSException",
  "JSPropertyAttribute",
  "JSClassAttribute",
  "JSObjectInitializeCallback",
  "JSObjectInitializeCallbackEx",
  "JSObjectFinalizeCallback",
  "JSObjectFinalizeCallbackEx",
  "JSObjectHasPropertyCallback",
  "JSObjectHasPropertyCallbackEx",
  "JSObjectGetPropertyCallback",
  "JSObjectGetPropertyCallbackEx",
  "JSObjectSetPropertyCallback",
  "JSObjectSetPropertyCallbackEx",
  "JSObjectDeletePropertyCallback",
  "JSObjectDeletePropertyCallbackEx",
  "JSObjectGetPropertyNamesCallback",
  "JSObjectGetPropertyNamesCallbackEx",
  "JSObjectCallAsFunctionCallback",
  "JSObjectCallAsFunctionCallbackEx",
  "JSObjectCallAsConstructorCallback",
  "JSObjectCallAsConstructorCallbackEx",
  "JSObjectHasInstanceCallback",
  "JSObjectHasInstanceCallbackEx",
  "JSObjectHasInstanceCallbackEx",
  "JSObjectConvertToTypeCallback",
  "JSObjectConvertToTypeCallbackEx",
  "JSStaticValue",
  "JSStaticValueEx",
  "JSStaticFunction",
  "JSStaticFunctionEx",
  "JSClassCallbacks",
  "JSClassCallbacksEx",
  "JSClassCallbacksUnion",
  "JSClassDefinition"
]

proc skipUntil*(s: string, token: var string, until: string,
                 start = 0): int {.inline.} =
  ## Chopped up version of https://github.com/nim-lang/Nim/blob/version-1-6/lib/pure/parseutils.nim#L370
  var i = start
  while i < s.len:
    if until.len > 0 and s[i] == until[0]:
      var u = 1
      while i+u < s.len and u < until.len and s[i+u] == until[u]:
        inc u
      if u >= until.len: break
    inc(i)
  result = i-start

# Common replacements in doc comments
const replacements = block:
    var tmp = newSeq[(string, string)](jsTypes.len)
    for typ in jsTypes:
      tmp &= (typ, typ & "_")
    tmp &= {
      "NULL": "`nil`",
      "void*": "pointer",
      "JSObject": "JSObjectRef_"
    }

    tmp
proc handleParam(name, body: string): string =
  result = "\n" & fmt"* **{name}**: {body.multiReplace(replacements).strip()}" 


proc convert(x: string): string =
  var i = 0
  while i < x.len:
    i += x.skipUntil('/', i) + 4 # skip past /*!
    var cdoc: string
    i += x.parseUntil(cdoc, "*/", i) + 2
    # Parse the docstring
    var
      docstring: string
      function: string
    for line in cdoc.split("@"):
      if line.isEmptyOrWhitespace(): continue
      let (ok, flag) = line.scanTuple("$s$w")
      case flag
      of "function":
        continue

      of "param":
        let (ok, name, body) = line.scanTuple("param $w $+$.")
        docstring &= handleParam(name, body.strip())

      of "abstract":
        docstring &= line.replace("abstract", "").multiReplace(replacements).strip() & "\n"
      of "result":
        let (ok, body) = line.scanTuple("result $+$.")
        docstring &= handleParam("returns", body)
      of "discussion":
        let (ok, body) = line.scanTuple("discussion $+$.")
        docstring &= "\n\n" & body.multiReplace(replacements).strip()
      else:
        quit("Unknown flag, " & flag, 1)
    var
      returnType, name: string
      parameters: seq[(string, string)]
    # Parse the function
    i += x.skipWhitespace(i)
    i += x.skip("JS_EXPORT ", i)
    i += x.parseUntil(returnType, ' ', i) + 1
    i += x.parseUntil(name, '(', i) + 1
    
    while x[i - 1] != ')':
      i += x.skipWhitespace(i)
      var parameter: (string, string)
      i += x.parseUntil(parameter[1], ' ', i) + 1
      i += x.parseUntil(parameter[0], {',', ')'}, i) + 1
      
      if parameter[1].endsWith("*"):
        parameter[1] = "ptr " & parameter[1][0..^2]
      else:
        case parameter[1]
        of "size_t":
          parameter[1] = "csize_t"
        of "int":
          parameter[1] = "cint"
        of "unsigned":
          parameter[1] = "cuint"
      
      parameters &= parameter
      
    i += x.skipUntil(';', i)
    inc i
    i += x.skipWhitespace(i)

    # Build the nim function
    var code: string
    code &= fmt"proc {name}*("
    for i, (param, kind) in parameters:
      code &= fmt"{param}: {kind}"
      if i != parameters.len - 1:
        code &= ", "
    code &= fmt"""): {returnType} {{.importc: "{name}".}}""" & "\n"

    code &= docstring.indent(1).indent(1, padding="  ##")
    echo code
    echo ""

echo convert readFile"js.h"
