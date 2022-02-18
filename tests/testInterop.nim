## This contains tests for interop between Nim and JS

import std/unittest
import tau
import utils
include headlessApp
import std/times

type
  Person = object
    name: string
    age: int

type
  RefPerson = ref Person

  ComplexType = ref object
    a {.jsHide.}, b {.jsHide.}: string
    name {.jsReadOnly.}: string
    allowed: bool


proc returnA(c: ComplexType): string =
  result = c.a

makeTypeWrapper(RefPerson)
makeTypeWrapper(ComplexType, returnA)
    

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
    test "DateTime":
      # We cant be exact to just roughly check
      # check ctx.evalScript("new Date(Date.now())", DateTime) == now()
      check (now() - ctx.evalScript("new Date(Date.now())", DateTime)).inSeconds <= 1
      
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

    test "Sending object across":
      let person = RefPerson(
        name: "John"
      )
      let ob = ctx.makeObject(RefPerson.makeJSClass(), cast[pointer](person))
      ctx.addToWindow("john", cast[JSValueRef](ob))
      check ctx.evalScript("john.name", string) == "John"
      person.name = "Not John"
      check ctx.evalScript("john.name", string) == "Not John"


    test "Pragmas are respected":
      let complex = ComplexType(
        a: "aValue",
        b: "bValue",
        name: "constant",
        allowed: true
      )
      let ob = ctx.makeObject(ComplexType.makeJSClass, cast[pointer](complex))
      ctx.addToWindow("comp", cast[JSValueRef](ob))
      # Hidden values
      template isUndefined(x: JSValueRef): bool =
        ctx.isUndefined(x)
      check ctx.evalScript("comp.a").isUndefined
      check ctx.evalScript("comp.b").isUndefined
      # Read only value
      discard ctx.evalScript("comp.name = 'test'")
      check ctx.evalScript("comp.name", string) == "constant"

      check ctx.evalScript("comp.allowed", bool)

    test "Object function":
      let complex = ComplexType(
        a: "This is a value"
      )
      let ob = ctx.makeObject(ComplexType.makeJSClass, cast[pointer](complex))
      ctx.addToWindow("comp", cast[JSValueRef](ob))
      check ctx.evalScript("comp.returnA()", string) == "This is a value"
      
  suite "Adding a function with wrapper macro":
    test "No params, no return":
      var ret: int # Still need to make sure it is called

      proc simple() =
        ret = 90

      makeProcWrapper("simpleJS", simple, exportProc = false)

      ctx.addToWindow("simple", simpleJS)
      discard ctx.evalScript("simple()")
      check ret == 90

    test "Params":
      var ret: int

      proc simple(x: int) =
        ret = x

      makeProcWrapper("simpleJS", simple, exportProc = false)
      ctx.addToWindow("simple", simpleJS)

    test "Return value":
      proc addNums(x, y: int): int =
        result = x + y

      makeProcWrapper("addJS", addNums, exportProc = false)
      ctx.addToWindow("add", addJS)
      check ctx.evalScript("add(9, 14)", int) == 23

    test "Invalid params":
      proc addNums(x, y: int): int =
        result = x + y
      makeProcWrapper("addJS", addNums, exportProc = false)
      ctx.addToWindow("add", addJS)

      expect JSError:
        discard ctx.evalScript("add(9)", int)

    test "Object function":
      let
        person = RefPerson(name: "Jake")
        obj = ctx.makeObject(RefPerson.makeJSClass(), cast[pointer](person))
    
      proc sayName(person: RefPerson): string =
        result = person.name
      makeProcWrapper("sayNameJS", sayName, exportProc = false, isObjFunc = true)
      
      let cname = createJSString "sayName"
      let funObj = ctx.makeFunctionWithCallback(cname, sayNameJS)
      release cname      

      var exception: JSValueRef
      let result = ctx.callAsFunction(funObj, obj, 0, nil, addr exception)
      if not exception.isNil:
        ctx.throwNim exception 
      check ctx.fromJSValue(result, string) == "Jake"
