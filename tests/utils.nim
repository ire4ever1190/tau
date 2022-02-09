import tau

proc evalScript*(ctx: JSContextRef, script: string): JSValueRef = 
  let scriptStr = createJSString script
  var exception: JSValueRef
  result = ctx.evalScript(
    scriptStr,
    nil,
    nil,
    1,
    addr exception
  )
  if not exception.isNil:
    ctx.throwNim exception
  release scriptStr
