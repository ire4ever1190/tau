## This contains tests for interop between Nim and JS

import std/unittest
import tau
import utils
import os

#
# Create headless instance
#

let config = createConfig()
  
enablePlatformFontLoader()
enablePlatformFileSystem(currentSourcePath.parentDir() / "assets")
enableDefaultLogger("./ultralight.log")

let
  renderer = createRenderer(config)
  session = createSession(renderer, false, "testInterop")
  viewConfig = createViewConfig()
  view = renderer.createView(500, 500, viewConfig, session)


type
  Person = object
    name: string
    age: int

proc evalScript[T](ctx: JSContextRef, script: string, retType: typedesc[T]): T = 
  ## Run script and convert return value to a Nim type
  result = ctx.fromJSValue(ctx.evalScript(script), retType)
    

withJSCtx view:
  suite "fromJSValue":
  
    test "int":
      check ctx.evalScript("10 + 42", int) == 52

    test "string":
      check ctx.evalScript("'Hello World'", string) == "Hello World"

    test "bool":
      check:
        not ctx.evalScript("false", bool)
        ctx.evalScript("true", bool)
        ctx.evalScript("1", bool)
        
    test "object":

      let john = ctx.evalScript("""
        let j = {
          "name": "John Doe",
          "age": 42
        }
        j
      """, Person)
      
      check:
        john.name == "John Doe"
        john.age == 42

    test "array[T]":
      check:
        ctx.evalScript("[1, 2, 6, 10]", array[4, int]) == [1, 2, 6, 10]
        ctx.evalScript("""
        [
          {
            "name": "John Doe 1",
            "age": 89
          },
          {
            "name": "Greg Doe",
            "age": 43
          },
                    
        ]
        """, array[2, Person]) == [
          Person(name: "John Doe 1", age: 89),
          Person(name: "Greg Doe", age: 43)
        ]

    test "seq[T]":
      check:
        ctx.evalScript("[199, 54, 23, 1]", seq[int]) == @[199, 54, 23, 1]
        ctx.evalScript("""
          [
            {
              "name": "Tory Done",
              "age": 43
            },
            {
              "name": "Harry Smith",
              "age": 104
            },
                      
          ]
          """, seq[Person]) == @[
            Person(name: "Tory Done", age: 43),
            Person(name: "Harry Smith", age: 104)
          ]

  suite "toJSValue":
    proc toAndBack[T](ctx: JSContextRef, val: T): T =
      ## Converts val into a JSValue and converts it back
      let jsValue = ctx.toJSValue(val)
      result = ctx.fromJSValue(jsValue, T)
      
    let people = [
                Person(name: "Tory Done", age: 43),
                Person(name: "Harry Smith", age: 104)
              ]
    tearDown:
      ctx.garbageCollect()
      
    test "int":
      check ctx.toAndBack(58) == 58

    test "string":
      check ctx.toAndBack("Hello from JS land") == "Hello from JS land"

    test "bool":
      check:
        ctx.toAndBack(true)
        not ctx.toAndBack(false)

    test "object":
      check ctx.toAndBack(people[0]) == people[0]

    test "array[T]":
      check ctx.toAndBack(people) == people

    test "seq[T]":
      check ctx.toAndBack(@people) == @people
      
  test "Adding global variable":
    ctx.addToWindow("theAnswer", ctx.toJSValue(42))
    check ctx.evalScript("window.theAnswer", int) == 42

  test "Adding a function":
    proc foo(ctx: JSContextRef, fun, this: JSObjectRef, argC: csize_t, 
             arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.cdecl.} =
      result = ctx.toJSValue(2509)
    ctx.addToWindow("foo", foo)
    check ctx.evalScript("foo()", int) == 2509

  # suite ""
