## This contains tests for interop between Nim and JS

import std/unittest
import tau
import utils
include headlessApp

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

  suite "Exceptions":
    test "ReferenceError":
      expect JSReferenceError:
        discard ctx.evalScript("person.walk()")

    test "RangeError":
      expect JSRangeError:
        discard ctx.evalScript("let a = 10; a.toFixed(99999999999999)")

    test "SyntaxError":
      expect JSSyntaxError:
        discard ctx.evalScript("""{"name": ""}""")

    test "TypeError":
      expect JSTypeError:
        discard ctx.evalScript("'hello'.speak()")

  suite "Adding a ref object via JSClass":
    type
      RefPerson = ref Person

      ComplexType = ref object
        a, b {.jsHide.}: bool
        name {.jsReadOnly.}: string
        section: string
    
    
    makeJSClassWrapper(RefPerson)

    test "Sending object across":
      let person = RefPerson(
        name: "Jake"
      )
      let ob = ctx.makeObject(RefPerson.makeJSClass(), cast[pointer](person))
      ctx.addToWindow("john", cast[JSValueRef](ob))
      check ctx.evalScript("john.name", string) == "Jake"
      person.name = "Not Jake"
      check ctx.evalScript("john.name", string) == "Not Jake"
    # makeJSClass(ComplexType)
    
  suite "Adding a function with wrapper macro":
    test "No params, no return":
      var ret: int # Still need to make sure it is called

      proc simple() =
        ret = 90

      makeWrapper("simpleJS", simple)

      ctx.addToWindow("simple", simpleJS)
      discard ctx.evalScript("simple()")
      check ret == 90

    test "Params":
      var ret: int

      proc simple(x: int) =
        ret = x

      makeWrapper("simpleJS", simple)
      ctx.addToWindow("simple", simpleJS)

    test "Return value":
      proc addNums(x, y: int): int =
        result = x + y

      makeWrapper("addJS", addNums)
      ctx.addToWindow("add", addJS)
      check ctx.evalScript("add(9, 14)", int) == 23

    test "Invalid params":
      proc addNums(x, y: int): int =
        result = x + y
      makeWrapper("addJS", addNums)
      ctx.addToWindow("add", addJS)

      expect JSError:
        discard ctx.evalScript("add(9)", int)
      echo ctx.evalScript("TypeError", string)
      # expect JSTypeError:
        # discard ctx.evalScript("add('hello', 9)", int)
    
