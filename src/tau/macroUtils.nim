import std/macros

type
  ProcParameter* = object
    name*: string
    kind*, defaultValue*: NimNode

proc `$`*(param: ProcParameter): string =
  if param.kind.kind != nnkEmpty:
    result &= "(name: " & param.name & ", "
    result &= "kind: " & $param.kind & ", "
    result &= "default: " & $param.defaultValue.toStrLit() & ")"

proc extractName*(node: NimNode): NimNode =
  ## Extracts name that might be hidden in a postfix*
  if node.kind == nnkPostFix:
    result = node[1]
  else:
    result = node

proc parameters*(prc: NimNode): seq[ProcParameter] =
  ## Returns list of parameters (first one is return type which will only have type set)
  ## Also performs other nicities such as 
  ## * unpacking multiple params of the same type
  ## * expanding using statements
  ## If the name is an empty string then it is the return type
  prc.expectKind(RoutineNodes)
  var index = 0
  for identDef in prc[3]:
    if index == 0: # Return type
      result &= ProcParameter(
        name: "",
        kind: identDef
      )
      inc index
    else:
      var 
        kind = identDef[^2]
        defaultValue = identDef[^1]
      if kind.kind == nnkEmpty:
        if defaultValue.kind == nnkEmpty:
          # It is actually a using statement
          kind = identDef[0].getTypeInst()
        else:
          # It has a default value so we can get the type
          # from that
          kind = identDef[^1].getType()
          
      for name in identDef[0 ..< ^2]:
        result &= ProcParameter(
          name: $name,
          kind: kind,
          defaultValue: defaultValue
        )
        inc index
