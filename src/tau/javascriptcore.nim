import common {.all.}
import std/macros
import std/times
import std/strformat
import macroUtils {.all.}
import std/genasts

{.experimental: "overloadableEnums".}
{.experimental: "codeReordering".}

##[
  This contains wrappers for javascriptcore along with helpers for repititative tasks


  Converting values
  =================

  Values can be converted between Nim and JS via `toJSValue` and `fromJSValue` procs. Most of these procs
  have two different versions with the difference between the versions being that one allows you to handle `JSExceptions` yourself
  while the other automatically raises a Nim exception

  You can overload the procs that are used for conversion so that your types are converted differently

  .. code-block:: nim

    proc fromJSValue(ctx: JSContextRef, val: JSValueRef, kind: typedesc[YourType], exception: JSException): YourType =
      # Convert the value stored in val

    proc toJSValue(ctx: JSContextRef, val: YourType, exception: JSException): JSValueRef = # exception parameter is optional
      # Convert YourType to a JS value somehow

  Garbage Collection
  ==================

  `Here <https://docs.ultralig.ht/docs/garbage-collected-types>`_ has a good overview on the garbage collection for Javascript types.
  For other types, it follows the same create/release rule i.e. You release everything that you create yourself


  Object vs Ref Objects
  ======================

  Both `object` and `ref object` types can be sent to JS. The difference is that `objects` are copied while `ref objects` are shared.
  The example below shows the difference between the two
]##

runnableExamples:
  include ../tests/headlessApp

  type
    PersonObj = object
      name: string
    Person = ref PersonObj

  makeTypeWrapper(Person) # This needs to be called before being sent to JS
  
  withJSCtx view:
    let
      personA = PersonObj(name: "foo")
      personB = Person(name: "bar")

      jsValA = ctx.toJSValue(personA)
      jsValB = ctx.toJSValue(personB)

    ctx.addToWindow({
      "personA": jsValA,
      "personB": jsValB
    })

    # Only the name on the JS side is getting edited
    discard ctx.evalScript("window.personA.name = 'not foo'")
    doAssert personA.name == "foo"

    # The name is changed via a setter and edits both JS and Nim sides
    discard ctx.evalScript("window.personB.name = 'not bar'")
    doAssert personB.name == "not bar"

# TODO: Make high level api
# something like this?
when false:
  type
    JSObject = object
      obj: JSObjectRef
      ctx: JSContext


# Pragmas for JS class annotations

template jsHide* {.pragma.}
  ## Hide the property from JS

template jsReadOnly* {.pragma.}
  ## Don't allow JS to set the object's value
  
type
  JSStruct* {.final, pure.} = object
  JSPtr* = ptr JSStruct

  JSContextGroupRef* = distinct ULPtr
    ## A group that associates JavaScript contexts with one another. Contexts in the same group may share and exchange JavaScript objects.
  JSGlobalContextRef* = distinct ULPtr
    ## A global JavaScript execution context. A JSGlobalContext is a JSContext.
  JSClassRef* = distinct ULPtr
    ## A JavaScript class. Used with JSObjectMake to construct objects with custom behavior. 
  JSPropertyNameArrayRef* = distinct ULPtr
    ## An array of JavaScript property names.
  JSPropertyNameAccumulatorRef* = distinct ULPtr
    ## An ordered set used to collect the names of a JavaScript object's properties.
  JSTypedArrayBytesDeallocator* = proc (bytes, deallocatorContext: pointer) {.cdecl, nimcall.}
    ## A function used to deallocate bytes passed to a Typed Array constructor. The function should take two arguments. 
    ## The first is a pointer to the bytes that were originally passed to the Typed Array constructor.
    ## The second is a pointer to additional information desired at the time the bytes are to be freed.
  JSContextRef*      = distinct JSPtr
    ## A JavaScript execution context. Holds the global object and other execution state.
  JSValueRef*        = distinct JSPtr
    ## A JavaScript value. The base type for all JavaScript values, and polymorphic functions on them.
  JSObjectRef*       = distinct JSPtr
    ## A JavaScript object. A JSObject is a JSValue.
  JSChar*            = distinct uint16
    ## A UTF-16 code unit. One, or a sequence of two, can encode any Unicode
    ## character. As with all scalar types, endianness depends on the underlying architecture.
  JSStringRef*       = distinct JSPtr
    ## A UTF16 character buffer. The fundamental string representation in JavaScript.

  JSException*       = ptr JSValueRef
    ## Used to get the exception from a callback
    
  JSPropertyAttribute* {.size: sizeof(cuint).} = enum
    ## * **None**: Specifies that a property has no special attributes.
    ## * **ReadOnly**: Specifies that a property is read-only.
    ## * **DontEnum**: Specifies that a property should not be enumerated by JSPropertyEnumerators and JavaScript for...in loops.
    ## * **DontDelete**: Specifies that the delete operation should fail on a property.
    None       
    ReadOnly  
    DontEnum   
    DontDelete 
    
  JSClassAttribute* {.size: sizeof(cuint).} = enum
    ## * **None**: Specifies that a class has no special attributes. 
    ## * **NoAutomaticPrototype**: Specifies that a class should not automatically generate a shared prototype for its instance objects. Use kJSClassAttributeNoAutomaticPrototype in combination with JSObjectSetPrototype to manage prototypes manually.
    None                
    NoAutomaticPrototype

  JSType* {.size: sizeof(cuint).} = enum
    ## A Constant identifying the type of a JSValueRef_
    ##
    ## * **Undefined**: The unique undefined value.
    ## * **Null**: The unique null value.
    ## * **Boolean**: A primitive boolean value, one of true or false.
    ## * **Number**: A primitive number value.
    ## * **String**: A primitive string value.
    ## * **Object**: An object value (meaning that this JSValueRef_ is a JSObjectRef_).
    ## * **TypeSymbol**: A primitive symbol value.
    Undefined
    Null
    Boolean
    Number
    String
    Object
    TypeSymbol

  JSTypedArrayType* {.size: sizeof(cuint).} = enum
    ## A constant identifying the Typed Array type of a JSObjectRef.
    ## 
    ## * **Int8**: `Int8Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Int8Array>`_
    ## * **Int16**: `Int16Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Int16Array>`_
    ## * **Int32**: `Int32Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Int32Array>`_
    ## * **Uint8**: `Uint8Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint8Array>`_
    ## * **Uint8Clamped**: `Uint8ClampedArray <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint8ClampedArray>`_
    ## * **Uint16**: `Uint16Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint16Array>`_
    ## * **Uint32**: `Uint32Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Uint32Array>`_
    ## * **Float32**: `Float32Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Float32Array>`_
    ## * **Float64**: `Float64Array <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Float64Array>`_
    ## * **ArrayBuffer**: ArrayBuffer
    ## * **None**: Not a typed array
    Int8
    Int16
    Int32
    Uint8
    Uint8Clamped
    Uint16
    Uint32
    Float32
    Float64
    ArrayBuffer
    None

  JSError* = object of CatchableError
    ## A JS error occurs when an exception is raised from the JS context
    orig: JSException # Store the original exception

  JSReferenceError* = object of JSError
    ## Occurs when a variable that doesn't exist (or hasn't been initialized) in the current scope is referenced (`source <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/ReferenceError>`_)

  JSRangeError* = object of JSError
    ## Occurs when a value is used when it is not in a range of allowed values (`source <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/RangeError>`_)

  JSSyntaxError* = object of JSError
    ## Occurs when you run syntactically incorrect code (`source <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SyntaxError>`_)

  JSTypeError* = object of JSError
    ## Occurs when a value is used in an incorrect way (Usually because it is the incorrect type) (`source <https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/TypeError>`_)

   
    
type
  JSObjectInitializeCallback* = proc (ctx: JSContextRef, obj: JSObjectRef) {.nimcall, cdecl.}
      ## The callback invoked when an object is first created.
      ##
      ## Unlike the other object callbacks, the initialize callback is called on the least
      ## derived class (the parent class) first, and the most derived class last.
      ##
      ## * **ctx**: The execution context to use.
      ## * **obj**: The JSObject being created.

  JSObjectInitializeCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef) {.nimcall, cdecl.}
    ## Extension of ObjectInitializeCallback_ with the class that the method is being invoked for.

  JSObjectFinalizeCallback* = proc (obj: JSObjectRef) {.nimcall, cdecl.}
    ## The callback invoked when an object is finalized (prepared for garbage collection). An object may be finalized on any thread.
    ##
    ## The finalize callback is called on the most derived class first, and the least 
    ## derived class (the parent class) last.
    ## You must not call any function that may cause a garbage collection or an allocation
    ## of a garbage collected object from within a JSObjectFinalizeCallback. This includes
    ## all functions that have a JSContextRef parameter.
    ##
    ## * **obj**: The JSObject being finalized.

  JSObjectFinalizeCallbackEx* = proc (jsClass: JSClassRef, obj: JSObjectRef) {.nimcall, cdecl.}
   ## Extension of JSObjectFinalizeCallback_ with the class that the method is being invoked for.

  JSObjectHasPropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef): bool {.nimcall, cdecl.}
    ## The callback invoked when determining whether an object has a property.
    ##
    ## If this function returns false, the hasProperty request forwards to object's statically declared properties, then its parent class chain (which includes the default object class), then its prototype chain.
    ## This callback enables optimization in cases where only a property's existence needs to be known, not its value, and computing its value would be expensive.
    ## If this callback is `nil`, the getProperty callback will be used to service hasProperty requests.
    ##
    ## * **ctx**: The execution context to use.
    ## * **obj**: The JSObject to search for the property.
    ## * **name**: A JSString containing the name of the property look up.
    ## * **return**: true if object has the property, otherwise false.

  JSObjectHasPropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef): bool {.nimcall, cdecl.}
    ## Extension of JSObjectHasPropertyCallback_ with the class that the method is being invoked for.

  JSObjectGetPropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): JSvalueRef {.nimcall, cdecl.}
    ## The callback invoked when getting a property's value.
    ##
    ## If this function returns `nil`, the get request forwards to object's statically declared properties, then its parent class chain (which includes the default object class), then its prototype chain.
    ##
    ## * **ctx**: The execution context to use.
    ## * **obj**: The JSObject to search for the property.
    ## * **name**: A JSString containing the name of the property to get.
    ## * **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ## * **return**: The property's value if object has the property, otherwise `nil`.

  JSObjectGetPropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectGetProperty_ with the class that the method is being invoked for.

  JSObjectSetPropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef, value: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## The callback invoked when setting a property's value.
    ##
    ## If this function returns false, the set request forwards to object's statically declared properties, then its parent class chain (which includes the default object class).
    ##
    ## * **ctx**: The execution context to use.
    ## * **obj**: The JSObject on which to set the property's value.
    ## * **name**: A JSString containing the name of the property to set.
    ## * **value**: A JSValue to use as the property's value.
    ## * **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ## * **return**: true if the property was set, otherwise false.

  JSObjectSetPropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef, value: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## Extension of JSObjectSetProperty_ with the class that the method is being invoked for.

  JSObjectDeletePropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): bool {.nimcall, cdecl.}
    ## The callback invoked when deleting a property.
    ##
    ## If this function returns false, the delete request forwards to object's statically declared properties, then its parent class chain (which includes the default object class).
    ##
    ## * **ctx**: The execution context to use.
    ## * **obj**: The JSObject in which to delete the property.
    ## * **name**: A JSString containing the name of the property to delete.
    ## * **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ## * **return**: true if propertyName was successfully deleted, otherwise false.

  JSObjectDeletePropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): bool {.nimcall, cdecl.}
    ## Extension of JSObjectDeleteProperty_ with the class that the method is being invoked for.

  JSObjectGetPropertyNamesCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, names: JSPropertyNameAccumulatorRef) {.nimcall, cdecl.}
    ## The callback invoked when collecting the names of an object's properties.
    ##
    ## Property name accumulators are used by JSObjectCopyPropertyNames_ and JavaScript for...in loops. 
    ## Use JSPropertyNameAccumulatorAddName_ to add property names to accumulator. A class's `getPropertyNames` callback only needs to provide the names of properties that the class vends through a custom getProperty or setProperty callback. Other properties, including statically declared properties, properties vended by other classes, and properties belonging to object's prototype, are added independently.
    ##
    ## * **ctx**: The execution context to use.
    ## * **object**: The JSObject whose property names are being collected.
    ## * **names**: A JavaScript property name accumulator in which to accumulate the names of object's properties.

  JSObjectGetPropertyNamesCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, propertyNames: JSPropertyNameAccumulatorRef) {.nimcall, cdecl.}
    ## Extension of JSObjectGetPropertyNamesCallback_ with the class that the method is being invoked for.

  JSObjectCallAsFunctionCallback* = proc (ctx: JSContextRef, function, this: JSObjectRef, argumentCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.nimcall, cdecl}
    ## The callback invoked when an object is called as a function.
    ##
    ## If your callback were invoked by the JavaScript expression 'myObject.myFunction()', `function` would be set to myFunction, and `this` would be set to myObject.
    ## If this callback is `nil`, calling your object as a function will throw an exception.
    ##
    ## * **ctx**: The execution context to use.
    ## * **function**: A JSObject that is the function being called.
    ## * **this**: A JSObject that is the `this` variable in the function's scope.
    ## * **argumentCount**: An integer count of the number of arguments in arguments.
    ## * **arguments**: A JSValue array of the arguments passed to the function.
    ## * **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ## * **return**: A JSValue that is the function's return value.

  JSObjectCallAsFunctionCallbackEx* = proc (ctx: JSContextRef, jsClass, className: JSStringRef, function, this: JSObjectRef, argCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectCallAsFunctionCallback_ with the class and class name of the object being called as a function. 
    ##
    ## If this is a JSStaticFunctionEx, className will actually be the name of the function.

  JSObjectCallAsConstructorCallback* = proc (ctx: JSContextRef, constrc: JSObjectRef, argumentCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.nimcall, cdecl}
    ## The callback invoked when an object is used as a constructor in a 'new' expression.
    ##
    ## If your callback were invoked by the JavaScript expression `new myConstructor()`, constructor would be set to myConstructor.
    ## If this callback is `nil`, using your object as a constructor in a 'new' expression will throw an exception.
    ##
    ## * **ctx**: The execution context to use.
    ## * **constructor**: A JSObject that is the constructor being called.
    ## * **argumentCount**: An integer count of the number of arguments in arguments.
    ## * **arguments**: A JSValue array of the arguments passed to the function.
    ## * **exception**: A pointer to a JSValueRef in which to return an **exception**:, if any.
    ## * **return**: A JSObject that is the constructor's return value.

  JSObjectCallAsConstructorCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, constrc: JSObjectRef, argumentCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectCallAsConstructorCallback_ with the class that the method is being invoked for.

  JSObjectHasInstanceCallback* = proc (ctx: JSContextRef, target: JSobjectRef, possibleInstance: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## hasInstance The callback invoked when an object is used as the target of an 'instanceof' expression.
    ##
    ## If your callback were invoked by the JavaScript expression 'someValue instanceof myObject', target would be set to `myObject` and possibleInstance would be set to `someValue`.
    ## If this callback is `nil`, 'instanceof' expressions that target your object will return false.
    ## Standard JavaScript practice calls for objects that implement the callAsConstructor callback to implement the hasInstance callback as well.
    ##
    ## * **ctx**: The execution context to use.
    ## * **constructor**: The JSObject that is the target of the 'instanceof' expression.
    ## * **possibleInstance**: The JSValue being tested to determine if it is an instance of constructor.
    ## * **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ## * **return**: true if possibleInstance is an instance of constructor, otherwise false.
    ##

  JSObjectHasInstanceCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, target: JSobjectRef, possibleInstance: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## Extension of JSObjectHasInstanceCallback_ with the class that the method is being invoked for.

  JSObjectConvertToTypeCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, kind: JSType, exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## The callback invoked when converting an object to a particular JavaScript type.
    ##
    ## If this function returns false, the conversion request forwards to object's parent class chain (which includes the default object class).
    ## This function is only invoked when converting an object to number or string. An object converted to boolean is 'true.' An object converted to object is itself.
    ##
    ## * **ctx**: The execution context to use.
    ## * **object**: The JSObject to convert.
    ## * **type**: A JSType specifying the JavaScript **type**: to convert to.
    ## * **exception**: A pointer to a JSValueRef in which to return an **exception**:, if any.
    ## * **return**: The objects's converted value, or `nil` if the object was not converted.

  JSObjectConvertToTypeCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, kind: JSType, exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectConvertToTypeCallback_ with the class that the method is being invoked for.
    

{.push header: "JavaScriptCore/JavaScript.h".}
type
  JSStaticValue* {.bycopy, importc.} = object 
    ## This structure describes a statically declared value property.
    ##
    ## * **name**: A null-terminated UTF8 string containing the property's **name**:.
    ## * **getProperty**: A JSObjectGetPropertyCallback to invoke when getting the property's value.
    ## * **setProperty**: A JSObjectSetPropertyCallback to invoke when setting the property's value. May be `nil` if the ReadOnly attribute is set.
    ## * **attributes**: A set of attributes to give to the property.
    name*: cstring
    getProperty*: JSObjectGetPropertyCallback
    setProperty*: JSObjectSetPropertyCallback
    attributes*: set[JSPropertyAttribute] 

  JSStaticValueEx* {.bycopy, importc.} = object
    ## Extension of JSStaticValue* for use with class version `1000`
    name*: cstring
    getProperty*: JSObjectGetPropertyCallbackEx
    setProperty*: JSObjectSetPropertyCallbackEx
    attributes*: set[JSPropertyAttribute] 

  JSStaticFunction* {.bycopy, importc.} = object
    ## This structure describes a statically declared function property.
    ##
    ## * **name**: A null-terminated UTF8 string containing the property's **name**:.
    ## * **callAsFunction**: A JSObjectCallAsFunctionCallback to invoke when the property is called as a function.
    ## * **attributes**: A set of attributes to give to the property.
    name*: cstring
    callAsFunction*: JSObjectCallAsFunctionCallback
    attributes*: set[JSPropertyAttribute]

  JSStaticFunctionEx* {.bycopy, importc.} = object
    ## Extension of JSStaticFunction* for use with class version 1000
    name*: cstring
    callAsFunction*: JSObjectCallAsFunctionCallbackEx
    attributes*: set[JSPropertyAttribute]


  # JSClassCallbacks* {.bycopy, union.} = object
    
  # JSClassCallbacksEx* {.bycopy, union.} = object
# 
  # JSClassCallbacksUnion* {.bycopy, union.} = object
    # callbacks: JSClassCallbacks
    # callbacksEx: JSClassCallbacksEx
    
  JSClassDefinition* {.bycopy, importc.} = object
    ## This structure contains properties and callbacks that define a type of object. All fields other than the version field are optional. Any pointer may be `nil`.
    ##
    ## The staticValues and staticFunctions arrays are the simplest and most efficient means for vending custom properties. Statically declared properties autmatically service requests like getProperty, setProperty, and getPropertyNames. Property access callbacks are required only to implement unusual properties, like array indexes, whose names are not known at compile-time.
    ##
    ## Standard JavaScript practice calls for storing function objects in prototypes, so they can be shared. The default JSClass created by JSClassCreate follows this idiom, instantiating objects with a shared, automatically generating prototype containing the class's function objects. The `NoAutomaticPrototype` attribute specifies that a JSClass should not automatically generate such a prototype. The resulting JSClass instantiates objects with the default object prototype, and gives each instance object its own copy of the class's function objects.
    ##
    ## A `nil` callback specifies that the default object callback should substitute, except in the case of hasProperty, where it specifies that getProperty should substitute.
    ##
    ## * **version**: The version number of this structure. Default is `0` but you should use `1000` for callbacks with extended class info.
    ## * **attributes**: A set of JSClassAttributes_ to give to the class.
    ## * **className**: A null-terminated UTF8 string containing the class's name.
    ## * **parentClass**: A JSClass to set as the class's parent class. Pass `nil` use the default object class.
    ## * **staticValues**: A JSStaticValue_ array containing the class's statically declared value properties. Pass `nil` to specify no statically declared value properties. The array must be terminated by a JSStaticValue_ whose name field is `nil`.
    ## * **staticFunctions**: A JSStaticFunction array containing the class's statically declared function properties. Pass `nil` to specify no statically declared function properties. The array must be terminated by a JSStaticFunction_ whose name field is `nil`.
    ## * **initialize**: The callback invoked when an object is first created. Use this callback to initialize the object.
    ## * **finalize**: The callback invoked when an object is finalized (prepared for garbage collection). Use this callback to release resources allocated for the object, and perform other cleanup.
    ## * **hasProperty**: The callback invoked when determining whether an object has a property. If this field is `nil`, getProperty is called instead. The hasProperty callback enables optimization in cases where only a property's existence needs to be known, not its value, and computing its value is expensive. 
    ## * **getProperty**: The callback invoked when getting a property's value.
    ## * **setProperty**: The callback invoked when setting a property's value.
    ## * **deleteProperty**: The callback invoked when deleting a property.
    ## * **getPropertyNames**: The callback invoked when collecting the names of an object's properties.
    ## * **callAsFunction**: The callback invoked when an object is called as a function.
    ## * **hasInstance**: The callback invoked when an object is used as the target of an 'instanceof' expression.
    ## * **callAsConstructor**: The callback invoked when an object is used as a constructor in a 'new' expression.
    ## * **convertToType**: The callback invoked when converting an object to a particular JavaScript type.
    version*: cint
    attributes: set[JSClassAttribute]
    className*: cstring
    parentClass*: JSClassRef
    # callbacks*: JSClassCallbacksUnion
    privateData*: pointer

    staticValues*: ptr JSStaticValue
    staticFunctions*: ptr JSStaticFunction
    initialize*: JSObjectInitializeCallback
    finalize*: JSObjectFinalizeCallback
    hasProperty*: JSObjectHasPropertyCallback
    getProperty*: JSObjectGetPropertyCallback
    setProperty*: JSObjectSetPropertyCallback
    deleteProperty*: JSObjectDeletePropertyCallback
    getPropertyNames*: JSObjectGetPropertyNamesCallback
    callAsFunction*: JSObjectCallAsFunctionCallback
    callAsConstructor*: JSObjectCallAsConstructorCallback
    hasInstance*: JSObjectHasInstanceCallback
    convertToType*: JSObjectConvertToTypeCallback
  
    staticValuesEx*: ptr JSStaticValueEx
    staticFunctionsEx*: ptr JSStaticFunctionEx
    initializeEx*: JSObjectInitializeCallbackEx
    finalizeEx*: JSObjectFinalizeCallbackEx
    hasPropertyEx*: JSObjectHasPropertyCallbackEx
    getPropertyEx*: JSObjectGetPropertyCallbackEx
    setPropertyEx*: JSObjectSetPropertyCallbackEx
    deletePropertyEx*: JSObjectDeletePropertyCallbackEx
    getPropertyNamesEx*: JSObjectGetPropertyNamesCallbackEx
    callAsFunctionEx*: JSObjectCallAsFunctionCallbackEx
    callAsConstructorEx*: JSObjectCallAsConstructorCallbackEx
    hasInstanceEx*: JSObjectHasInstanceCallbackEx
    convertToTypeEx*: JSObjectConvertToTypeCallbackEx
    
{.pop.}    

{.push header: "JavaScriptCore/JavaScript.h", dynlib: DLLWebCore.} # Think this is the right dynamic lib

# TODO: Split files up and use includes

#
# JSBase.h
#

proc evalScript*(ctx: JSContextRef, script: JSStringRef, this: JSObjectRef, 
                sourceURL: JSStringRef, startLineNumber: cint, exception: ptr JSValueRef): JSValueRef {.importc: "JSEvaluateScript".}
  ## Evaluates a string of JavaScript.
  ## `evalScript <ultralight.html#evalScript%2CView%2CULString%2Cptr.ULStringWeak>`_ Can be used instead to evaluate directly against a view
  ##
  ## * **ctx**: The execution context to use.
  ## * **script**: A JSString containing the script to evaluate.
  ## * **this**: The object to use as "this," or `nil` to use the global object as "this".
  ## * **sourceURL**: A JSString containing a URL for the script's source file. This is used by debuggers and when reporting exceptions. Pass `nil` if you do not care to include source file information.
  ## * **startLineNumber**: An integer value specifying the script's starting line number in the file located at `sourceURL`. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ## * **exception**: A pointer to a JSValueRef in which to store an exception, if any. Pass **nil** if you do not care to store an exception.
  ## * **return**: The JSValue that results from evaluating script, or `nil` if an exception is thrown.

proc checkScriptSyntax*(ctx: JSContextRef, script, sourceURL: JSStringRef, startLineNumer: cint, exception: ptr JSValueRef): bool {.importc: "JSCheckScriptSyntax".}
  ## Checks for syntax errors in a string of JavaScript.
  ##
  ## * **ctx**: The execution context to use.
  ## * **script**: A JSString containing the **script** to check for syntax errors.
  ## * **sourceURL**: A JSString containing a URL for the script's source file. This is only used when reporting exceptions. Pass `nil` if you do not care to include source file information in exceptions.
  ## * **startingLineNumber**: An integer value specifying the script's starting line number in the file located at sourceURL. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ## * **exception**: A pointer to a JSValueRef in which to store a syntax error `exception`, if any. Pass `nil` if you do not care to store a syntax error exception.
  ## * **return**: if the script is syntactically correct, otherwise false.

proc garbageCollect*(ctx: JSContextRef) {.importc: "JSGarbageCollect".}
  ## Performs a JavaScript garbage collection.
  ##
  ## JavaScript values that are on the machine stack, in a register,
  ## protected by JSValueProtect, set as the global object of an execution context,
  ## or reachable from any such value will not be collected.
  ## During JavaScript execution, you are not required to call this function; the
  ## JavaScript engine will garbage collect as needed. JavaScript values created
  ## within a context group are automatically destroyed when the last reference
  ## to the context group is released.
  ##
  ## **ctx**: The execution context to use.

#
# JSContextRef.h
#

proc createContextGroup(): JSContextGroupRef {.importc: "JSContextGroupCreate".}
  ##  Creates a JavaScript context group.
  ## 
  ## A JSContextGroup_ associates JavaScript contexts with one another.
  ##  Contexts in the same group may share and exchange JavaScript objects. Sharing and/or exchanging
  ##  JavaScript objects between contexts in different groups will produce undefined behavior.
  ##  When objects from the same context group are used in multiple threads, explicit
  ##  synchronization is required.
  ##  A JSContextGroup may need to run deferred tasks on a run loop, such as garbage collection
  ##  or resolving WebAssembly compilations. By default, calling createContextGroup_ will use
  ##  the run loop of the thread it was called on. Currently, there is no API to change a
  ##  JSContextGroup's run loop once it has been created.
  ## 
  ## * **returns**: The created JSContextGroup.
  ## 

proc retain(group: JSContextGroupRef): JSContextGroupRef {.importc: "JSContextGroupRetain".}
  ##  Retains a JavaScript context group.
  ## 
  ## * **group**: The JSContextGroup to retain.
  ## * **returns**: A JSContextGroup that is the same as group.
  ## 

proc release(group: JSContextGroupRef): void {.importc: "JSContextGroupRelease".}
  ##  Releases a JavaScript context group.
  ## 
  ## * **group**: The JSContextGroup to release.

proc createGlobalContext(globalObjectClass: JSClassRef): JSGlobalContextRef {.importc: "JSGlobalContextCreate".}
  ##  Creates a global JavaScript execution context.
  ## 
  ## JSGlobalContextCreate allocates a global object and populates it with all the
  ##  built-in JavaScript objects, such as Object, Function, String, and Array.
  ##  In WebKit version 4.0 and later, the context is created in a unique context group.
  ##  Therefore, scripts may execute in it concurrently with scripts executing in other contexts.
  ##  However, you may not use values created in the context in other contexts.
  ## 
  ## * **globalObjectClass**: The class to use when creating the global object. Pass `nil` to use the default object class.
  ## * **returns**: A JSGlobalContext with a global object of class globalObjectClass.
  ## 

proc createGlobalContext(group: JSContextGroupRef, globalObjectClass: JSClassRef): JSGlobalContextRef {.importc: "JSGlobalContextCreateInGroup".}
  ##  Creates a global JavaScript execution context in the context group provided.
  ## 
  ## this allocates a global object and populates it with
  ##  all the built-in JavaScript objects, such as Object, Function, String, and Array.
  ## 
  ## * **globalObjectClass**: The class to use when creating the global object. Pass `nil` to use the default object class.
  ## * **group**: The context group to use. The created global context retains the group. Pass `nil` to create a unique group for the context.
  ## * **returns**: A JSGlobalContext with a global object of class globalObjectClass and a context group equal to group.
  ## 

proc retain(ctx: JSGlobalContextRef): JSGlobalContextRef {.importc: "JSGlobalContextRetain".}
  ##  Retains a global JavaScript execution context.
  ## 
  ## * **ctx**: The JSGlobalContext to retain.
  ## * **returns**: A JSGlobalContext that is the same as ctx.
  ## 

proc release(ctx: JSGlobalContextRef): void {.importc: "JSGlobalContextRelease".}
  ##  Releases a global JavaScript execution context.
  ## 
  ## * **ctx**: The JSGlobalContextRef_ to release.

proc globalObj*(ctx: JSContextRef): JSObjectRef {.importc: "JSContextGetGlobalObject".}
  ##  Gets the global object of a JavaScript execution context.
  ## 
  ## * **ctx**: The JSContext whose global object you want to get.
  ## * **returns**: ctx's global object.
  ## 

proc group(ctx: JSContextRef): JSContextGroupRef {.importc: "JSContextGetGroup".}
  ##  Gets the context group to which a JavaScript execution context belongs.
  ## 
  ## * **ctx**: The JSContext whose group you want to get.
  ## * **returns**: ctx's group.
  ## 

proc globalCtx*(ctx: JSContextRef): JSGlobalContextRef {.importc: "JSContextGetGlobalContext".}
  ##  Gets the global context of a JavaScript execution context.
  ## 
  ## * **ctx**: The JSContext whose global context you want to get.
  ## * **returns**: ctx's global context.
  ## 

proc copyName(ctx: JSGlobalContextRef): JSStringRef {.importc: "JSGlobalContextCopyName".}
  ##  Gets a copy of the name of a context.
  ## 
  ## * **ctx**: The JSGlobalContext whose name you want to get.
  ## * **returns**: The name for ctx.
  ## 
  ## A JSGlobalContext's name is exposed for remote debugging to make it
  ## easier to identify the context you would like to attach to.
  ## 

proc `name=`*(ctx: JSGlobalContextRef, name: JSStringRef): void {.importc: "JSGlobalContextSetName".}
  ##  Sets the remote debugging name for a context.
  ## 
  ## * **ctx**: The JSGlobalContext that you want to name.
  ## * **name**: The remote debugging name to set on ctx.


#
# JSObjectRef.h
#

let JSClassDefinitionEmpty* {.importc: "kJSClassDefinitionEmpty".}: JSClassDefinition
  ## A JSClassDefinition structure of the current version, filled with `nil` pointers and having no attributes.
  ##
  ## Use this constant as a convenience when creating class definitions. For example, to create a class definition with only a finalize method:
  ##
  ## .. code-block:: nim
  ##  let definition = JSClassDefinitionEmpty;
  ##  definition.finalize = finalize # Finalize proc is an exercise left to the reader

proc classCreate*(definition: ptr JSClassDefinition): JSClassRef {.importc: "JSClassCreate".}=
  ## Creates a JavaScript class suitable for use with JSObjectMake.
  ##
  ## * **definition**: A JSClassDefinition_ that defines the class.
  ## * **return**: A JSClassRef_ with the given definition. Ownership follows the Create Rule.

proc retain*(jsClass: JSClassRef): JSClassRef {.importc: "JSClassRetain".}
  ## Retains a JavaScript class.
  ##
  ## * **jsClass**: The JSClass to retain.
  ## * **return**: A JSClass that is the same as jsClass.

proc release*(jsClass: JSClassRef) {.importc: "JSClassRelease".} 
  ## Releases a JavaScript class.
  ##
  ## * **jsClass**: The JSClass to release.

proc getPrivate*(jsClass: JSClassRef): pointer {.importc: "JSClassGetPrivate".}
  ## Retrieves the private data from a class reference, only possible with classes created with version 1000 (extended callbacks).
  ##
  ## Only classes with version 1000 (extended callbacks) can store private data, for other classes always `nil` will always be returned.
  ## 
  ## * **jsClass**: The class to get the data from
  ## * **return**: The private data on the class, or `nil`, if not set

proc setPrivate*(jsClass: JSClassRef, data: pointer): bool {.importc: "JSClassSetPrivate".}
  ## Sets the private data on a class, only possible with classes created with version 1000 (extended callbacks).
  ##
  ## Only classes with version 1000 (extended callbacks) can store private data, for other classes the function always fails. The set pointer is not touched by the engine.
  ## 
  ## * **jsClass**: The class to set the data on
  ## * **data**: A pointer to set as the private data for the class
  ## * **return**: true if the data has been set on the class, false if the class has not been created with version 1000 (extended callbacks)

proc makeObject*(ctx: JSContextRef, jsClass: JSClassRef, data: pointer): JSObjectRef {.importc: "JSObjectMake".}
  ## Creates a JavaScript object.
  ##
  ## The default object class does not allocate storage for private data, so you must provide a non-`nil` jsClass to JSObjectMake if you want your object to be able to store private data.
  ## data is set on the created object before the intialize methods in its class chain are called. This enables the initialize methods to retrieve and manipulate data through JSObjectGetPrivate.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **jsClass**: The JSClassRef_ to assign to the object. Pass `nil` to use the default object class.
  ## * **data**: A pointer to set as the object's private data. Pass `nil` to specify no private data.
  ## * **return**: A JSObjectRef_ with the given class and private data.

proc makeFunctionWithCallback*(ctx: JSContextRef, name: JSStringRef, function: JSObjectCallAsFunctionCallback): JSObjectRef {.importc: "JSObjectMakeFunctionWithCallback".}
  ## Convenience method for creating a JavaScript function with a given callback as its implementation.
  ##
  ## * **ctx**: The execution context to use.
  ## * **name**: A JSStringRef_ containing the function's name. This will be used when converting the function to string. Pass `nil` to create an anonymous function.
  ## * **function**: The JSObjectCallAsFunctionCallback_ to invoke when the function is called.
  ## * **return**: A JSObjectRef_ that is a function. The object's prototype will be the default function prototype.

proc makeConstructor*(ctx: JSContextRef, jsClass: JSClassRef, constrc: JSObjectCallAsConstructorCallback): JSObjectRef {.importc: "JSObjectMakeConstructor".}
  ## Convenience method for creating a JavaScript constructor.
  ## The default object constructor takes no arguments and constructs an object of class jsClass with no private data.
  ##
  ## * **ctx** The execution context to use.
  ## * **jsClass** A JSClass that is the class your constructor will assign to the objects its constructs. jsClass will be used to set the constructor's .prototype property, and to evaluate 'instanceof' expressions. Pass `nil` to use the default object class.
  ## * **constrc** A JSObjectCallAsConstructorCallback to invoke when your constructor is used in a 'new' expression. Pass NULL to use the default object constructor.
  ## * **return** A JSObjectRef_ that is a constructor. The object's prototype will be the default object prototype.

proc makeArray*(ctx: JSContextRef, argumentCount: csize_t, arguments: ptr JSValueRef, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectMakeArray".}
  ##  Creates a JavaScript Array object.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **argumentCount**: An integer count of the number of arguments in arguments.
  ## * **arguments**: A JSValue array of data to populate the Array with. Pass `nil` if argumentCount is 0.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is an Array.
  ##  
  ## The behavior of this function does not exactly match the behavior of the built-in Array constructor. Specifically, if one argument 
  ##  is supplied, this function returns an array with one element.
  ##  

proc makeDate*(ctx: JSContextRef, argumentCount: csize_t, arguments: ptr JSValueRef, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectMakeDate".}
  ##  Creates a JavaScript Date object, as if by invoking the built-in Date constructor.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **argumentCount**: An integer count of the number of arguments in arguments.
  ## * **arguments**: A JSValue array of arguments to pass to the Date Constructor. Pass `nil` if argumentCount is 0.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a Date.
  ##  

proc makeError*(ctx: JSContextRef, argumentCount: csize_t, argument: ptr JSValueRef, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectMakeError".}
  ##  Creates a JavaScript Error object, as if by invoking the built-in Error constructor.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **argumentCount**: An integer count of the number of arguments in arguments.
  ## * **arguments**: A JSValue array of arguments to pass to the Error Constructor. Pass `nil` if argumentCount is 0.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a Error.
  ##  

proc makeRegExp*(ctx: JSContextRef, argumentCount: csize_t, arguments: ptr JSValueRef, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectMakeRegExp".}
  ##  Creates a JavaScript RegExp object, as if by invoking the built-in RegExp constructor.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **argumentCount**: An integer count of the number of arguments in arguments.
  ## * **arguments**: A JSValue array of arguments to pass to the RegExp Constructor. Pass `nil` if argumentCount is 0.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a RegExp.
  ##  

proc makeDeferredPromise*(ctx: JSContextRef, resolve: ptr JSObjectRef, reject: ptr JSObjectRef, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectMakeDeferredPromise".}
  ##  Creates a JavaScript promise object by invoking the provided executor.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **resolve**: A pointer to a JSObjectRef_ in which to store the resolve function for the new promise. Pass `nil` if you do not care to store the resolve callback.
  ## * **reject**: A pointer to a JSObjectRef_ in which to store the reject function for the new promise. Pass `nil` if you do not care to store the reject callback.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a promise or `nil` if an exception occurred.
  ##  

proc makeFunction*(ctx: JSContextRef, name: JSStringRef, parameterCount: cuint, parameterNames: UncheckedArray[JSStringRef], body: JSStringRef, sourceURL: JSStringRef, startingLineNumber: cint, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectMakeFunction".}
  ##  Creates a function with a given script as its body. Use makeFunctionWithCallback_ if you want to use Nim code
  ## 
  ## * **ctx**: The execution context to use.
  ## * **name**: A JSString containing the function's name. This will be used when converting the function to string. Pass `nil` to create an anonymous function.
  ## * **parameterCount**: An integer count of the number of parameter names in parameterNames.
  ## * **parameterNames**: A JSString array containing the names of the function's parameters. Pass `nil` if parameterCount is 0.
  ## * **body**: A JSString containing the script to use as the function's body.
  ## * **sourceURL**: A JSString containing a URL for the script's source file. This is only used when reporting exceptions. Pass `nil` if you do not care to include source file information in exceptions.
  ## * **startingLineNumber**: An integer value specifying the script's starting line number in the file located at sourceURL. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ## * **exception**: A pointer to a JSValueRef_ in which to store a syntax error exception, if any. Pass `nil` if you do not care to store a syntax error exception.
  ## * **returns**: A JSObjectRef_ that is a function, or `nil` if either body or parameterNames contains a syntax error. The object's prototype will be the default function prototype.
  ## 
  ## Use this method when you want to execute a script repeatedly, to avoid the cost of re-parsing the script before each execution.
  ## 

proc getPrototype*(ctx: JSContextRef, obj: JSObjectRef): JSValueRef {.importc: "JSObjectGetPrototype".}
  ##  Gets an object's prototype.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: A JSObjectRef_ whose prototype you want to get.
  ## * **returns**: A JSValue that is the object's prototype.
  ## 

proc setPrototype*(ctx: JSContextRef, obj: JSObjectRef, value: JSValueRef) {.importc: "JSObjectSetPrototype".}
  ##  Sets an object's prototype.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose prototype you want to set.
  ## * **value**: A JSValue to set as the object's prototype.

proc hasProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef): bool {.importc: "JSObjectHasProperty".}
  ##  Tests whether an object has a given property.
  ## 
  ## * **obj**: The JSObjectRef_ to test.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **returns**: true if the object has a property whose name matches propertyName, otherwise false.
  ## 

proc getProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef, exception: ptr JSValueRef): JSValueRef {.importc: "JSObjectGetProperty".}
  ##  Gets a property from an object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to get.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The property's value if object has the property, otherwise the undefined value.
  ## 

proc setProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef, value: JSValueRef, attributes: cuint, exception: ptr JSValueRef): void {.importc: "JSObjectSetProperty".}
  ##  Sets a property on an object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to set.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **value**: A JSValueRef_ to use as the property's value.
  ## * **attributes**: A logically ORed set of JSPropertyAttributes_ to give to the property.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.

proc delProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef, exception: ptr JSValueRef): bool {.importc: "JSObjectDeleteProperty".}
  ##  Deletes a property from an object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to delete.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: true if the delete operation succeeds, otherwise false (for example, if the property has the kJSPropertyAttribute_DontDelete attribute set).
  ## 

proc hasProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyKey: JSValueRef, exception: ptr JSValueRef): bool {.importc: "JSObjectHasPropertyForKey".}
  ##  Tests whether an object has a given property using a JSValueRef_ as the property key.
  ##  
  ## * **obj**: The JSObjectRef_ to test.
  ## * **propertyKey**: A JSValueRef_ containing the property key to use when looking up the property.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: true if the object has a property whose name matches propertyKey, otherwise false.
  ##  
  ## This function is the same as performing `propertyKey in object` from JavaScript.
  ##  

proc getProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyKey: JSValueRef, exception: ptr JSValueRef): JSValueRef {.importc: "JSObjectGetPropertyForKey".}
  ##  Gets a property from an object using a JSValueRef_ as the property key.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to get.
  ## * **propertyKey**: A JSValueRef_ containing the property key to use when looking up the property.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The property's value if object has the property key, otherwise the undefined value.
  ##  
  ## This function is the same as performing `object[propertyKey]` from JavaScript.
  ##  

proc setProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyKey: JSValueRef, value: JSValueRef, attributes: cuint, exception: ptr JSValueRef): void {.importc: "JSObjectSetPropertyForKey".}
  ##  Sets a property on an object using a JSValueRef_ as the property key.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to set.
  ## * **propertyKey**: A JSValueRef_ containing the property key to use when looking up the property.
  ## * **value**: A JSValueRef_ to use as the property's value.
  ## * **attributes**: A logically ORed set of JSPropertyAttributes_ to give to the property.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## This function is the same as performing `object[propertyKey] = value` from JavaScript.
  ##  

proc delProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyKey: JSValueRef, exception: ptr JSValueRef): bool {.importc: "JSObjectDeletePropertyForKey".}
  ##  Deletes a property from an object using a JSValueRef_ as the property key.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to delete.
  ## * **propertyKey**: A JSValueRef_ containing the property key to use when looking up the property.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: true if the delete operation succeeds, otherwise false (for example, if the property has the `DontDelete` attribute set).
  ##  
  ## This function is the same as performing `delete object[propertyKey]` from JavaScript.
  ##  

proc getPropertyAtIndex*(ctx: JSContextRef, obj: JSObjectRef, propertyIndex: cuint, exception: ptr JSValueRef): JSValueRef {.importc: "JSObjectGetPropertyAtIndex".}
  ##  Gets a property from an object by numeric index.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to get.
  ## * **propertyIndex**: An integer value that is the property's name.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The property's value if object has the property, otherwise the undefined value.
  ## 
  ## Calling this is equivalent to calling getProperty_ with a string containing propertyIndex, but this provides optimized access to numeric properties.
  ## 

proc setPropertyAtIndex*(ctx: JSContextRef, obj: JSObjectRef, propertyIndex: cuint, value: JSValueRef, exception: ptr JSValueRef): void {.importc: "JSObjectSetPropertyAtIndex".}
  ##  Sets a property on an object by numeric index.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose property you want to set.
  ## * **propertyIndex**: The property's name as a number.
  ## * **value**: A JSValue to use as the property's value.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ##
  ## Calling this is equivalent to calling setProperty_ with a string containing propertyIndex, but this provides optimized access to numeric properties.
  ## 

proc getPrivate*(obj: JSObjectRef): pointer {.importc: "JSObjectGetPrivate".}
  ##  Gets an object's private data.
  ## 
  ## * **obj**: A JSObjectRef_ whose private data you want to get.
  ## * **returns**: A pointer that is the object's private data, if the object has private data, otherwise `nil`.
  ## 

proc setPrivate*(obj: JSObjectRef, data: pointer): bool {.importc: "JSObjectSetPrivate".}
  ##  Sets a pointer to private data on an object.
  ## 
  ## * **obj**: The JSObjectRef_ whose private data you want to set.
  ## * **data**: A pointer to set as the object's private data.
  ## * **returns**: true if object can store private data, otherwise false.
  ## 
  ## The default object class does not allocate storage for private data. Only objects created with a non-NULL JSClass can store private data.
  ## 

proc isFunction*(ctx: JSContextRef, obj: JSObjectRef): bool {.importc: "JSObjectIsFunction".}
  ##  Tests whether an object can be called as a function.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ to test.
  ## * **returns**: `true` if the object can be called as a function, otherwise `false`.
  ## 

proc callAsFunction*(ctx: JSContextRef, fun: JSObjectRef, this: JSObjectRef, argumentCount: csize_t, arguments: ptr JSValueRef, exception: ptr JSValueRef): JSValueRef {.importc: "JSObjectCallAsFunction".}
  ##  Calls an object as a function.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **fun**: The JSObjectRef_ to call as a function.
  ## * **this**: The object to use as "this," or `nil` to use the global object as "this."
  ## * **argumentCount**: An integer count of the number of arguments in arguments.
  ## * **arguments**: A JSValue array of arguments to pass to the function. Pass `nil` if argumentCount is 0.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The JSValue that results from calling object as a function, or `nil` if an exception is thrown or object is not a function.
  ## 

proc isConstructor*(ctx: JSContextRef, obj: JSObjectRef): bool {.importc: "JSObjectIsConstructor".}
  ##  Tests whether an object can be called as a constructor.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ to test.
  ## * **returns**: true if the object can be called as a constructor, otherwise false.
  ## 

proc callAsConstructor*(ctx: JSContextRef, obj: JSObjectRef, argumentCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectCallAsConstructor".}
  ##  Calls an object as a constructor.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ to call as a constructor.
  ## * **argumentCount**: An integer count of the number of arguments in arguments.
  ## * **arguments**: A JSValue array of arguments to pass to the constructor. Pass `nil` if argumentCount is 0.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The JSObjectRef_ that results from calling object as a constructor, or `nil` if an exception is thrown or object is not a constructor.
  ## 

proc copyPropertyNames*(ctx: JSContextRef, obj: JSObjectRef): JSPropertyNameArrayRef {.importc: "JSObjectCopyPropertyNames".}
  ##  Gets the names of an object's enumerable properties.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The object whose property names you want to get.
  ## * **returns**: A JSPropertyNameArray containing the names object's enumerable properties. Ownership follows the Create Rule.
  ## 

proc retain*(arr: JSPropertyNameArrayRef): JSPropertyNameArrayRef {.importc: "JSPropertyNameArrayRetain".}
  ##  Retains a JavaScript property name array.
  ## 
  ## * **arr**: The JSPropertyNameArray to retain.
  ## * **returns**: A JSPropertyNameArray that is the same as array.
  ## 

proc release*(arr: JSPropertyNameArrayRef): void {.importc: "JSPropertyNameArrayRelease".}
  ##  Releases a JavaScript property name array.
  ## 
  ## * **arr**: The JSPropetyNameArray to release.

proc len*(arr: JSPropertyNameArrayRef): csize_t {.importc: "JSPropertyNameArrayGetCount".}
  ##  Gets a count of the number of items in a JavaScript property name array.
  ## 
  ## * **arr**: The array from which to retrieve the count.
  ## * **returns**: An integer count of the number of names in array.
  ## 

proc `[]`*(arr: JSPropertyNameArrayRef, index: csize_t): JSStringRef {.importc: "JSPropertyNameArrayGetNameAtIndex".}
  ##  Gets a property name at a given index in a JavaScript property name array.
  ## 
  ## * **arr**: The array from which to retrieve the property name.
  ## * **index**: The index of the property name to retrieve.
  ## * **returns**: A JSStringRef_ containing the property name.
  ## 

proc addName*(accumulator: JSPropertyNameAccumulatorRef, propertyName: JSStringRef): void {.importc: "JSPropertyNameAccumulatorAddName".}
  ##  Adds a property name to a JavaScript property name accumulator.
  ## 
  ## * **accumulator**: The accumulator object to which to add the property name.
  ## * **propertyName**: The property name to add.

#
# JSObjectRefPrivate
#

proc JSObjectSetPrivateProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef, value: JSValueRef): bool {.importc: "JSObjectSetPrivateProperty".}
  ##  Sets a private property on an object.  This private property cannot be accessed from within JavaScript.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose private property you want to set.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **value**: A JSValue to use as the property's value.  This may be `nil`.
  ## * **returns**: true if object can store private data, otherwise false.
  ##  
  ## This API allows you to store JS values directly an object in a way that will be ensure that they are kept alive without exposing them to JavaScript code and without introducing the reference cycles that may occur when using JSValueProtect.
  ##  The default object class does not allocate storage for private data. Only objects created with a non-NULL JSClass can store private properties.
  ##  

proc getPrivateProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef): JSValueRef {.importc: "JSObjectGetPrivateProperty".}
  ##  Gets a private property from an object.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose private property you want to get.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **returns**: The property's value if object has the property, otherwise `nil`.
  ##  

proc delPrivateProperty*(ctx: JSContextRef, obj: JSObjectRef, propertyName: JSStringRef): bool {.importc: "JSObjectDeletePrivateProperty".}
  ##  Deletes a private property from an object.
  ##  
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose private property you want to delete.
  ## * **propertyName**: A JSString containing the property's name.
  ## * **returns**: true if object can store private data, otherwise false.
  ##  
  ## The default object class does not allocate storage for private data. Only objects created with a non-NULL JSClass can store private data.
  ## 

proc proxyTarget(obj: JSObjectRef): JSObjectRef {.importc: "JSObjectGetProxyTarget".}
  ## Gets the proxy target for an object

proc globalContext(obj: JSObjectRef): JSGlobalContextRef {.importc: "JSObjectGetGlobalContext".}
  ## Gets the global context for an object

#
# JSStringRef
#

proc createJSString*(chars: ptr JSChar, numChars: csize_t): JSStringRef {.importc: "JSStringCreateWithCharacters".}
  ## Creates a JavaScript string from a buffer of Unicode characters.
  ## 
  ## * **chars**: The buffer of Unicode characters to copy into the new JSString.
  ## * **numChars**: The number of characters to copy from the buffer pointed to by chars.
  ## * **returns**: A JSString containing chars. Ownership follows the Create Rule.
  ## 

proc createJSString*(str: cstring): JSStringRef {.importc: "JSStringCreateWithUTF8CString".}
  ## Creates a JavaScript string from a null-terminated UTF8 string.
  ## 
  ## * **string**: The null-terminated UTF8 string to copy into the new JSString.
  ## * **returns**: A JSString containing string. Ownership follows the Create Rule.
  ## 

proc retain*(str: JSStringRef): JSStringRef {.importc: "JSStringRetain".}
  ## Retains a JavaScript string.
  ## 
  ## * **str**: The JSString to retain.
  ## * **returns**:           A JSString that is the same as string.
  ## 

proc release*(str: JSStringRef): void {.importc: "JSStringRelease".}
  ## Releases a JavaScript string.
  ## 
  ## * **str**: The JSString to release.

proc unicodeLen*(str: JSStringRef): csize_t {.importc: "JSStringGetLength".}
  ## Returns the number of Unicode characters in a JavaScript string.
  ## 
  ## * **str**: The JSString whose length (in Unicode characters) you want to know.
  ## * **returns**: The number of Unicode characters stored in string.
  ## 

proc charactersPtr*(str: JSStringRef): ptr JSChar {.importc: "JSChar* JSStringGetCharactersPtr".}
  ## Returns a pointer to the Unicode character buffer that serves as the backing store for a JavaScript string.
  ## 
  ## * **str**: The JSString whose backing store you want to access.
  ## * **returns**: A pointer to the Unicode character buffer that serves as string's backing store, which will be deallocated when string is deallocated.
  ## 

proc len*(str: JSStringRef): csize_t {.importc: "JSStringGetMaximumUTF8CStringSize".}
  ##  Returns the maximum number of bytes a JavaScript string will 
  ##  take up if converted into a null-terminated UTF8 string.
  ## 
  ## * **str**: The JSString whose maximum converted size (in bytes) you want to know.
  ## * **returns**: The maximum number of bytes that could be required to convert string into a null-terminated UTF8 string. The number of bytes that the conversion actually ends up requiring could be less than this, but never more.
  ## 

proc getCString*(str: JSStringRef, buffer: ptr char, bufferSize: csize_t): csize_t {.importc: "JSStringGetUTF8CString".}
  ## Converts a JavaScript string into a `cstring`, and copies the result into an external byte buffer.
  ## 
  ## * **str**: The source JSString.
  ## * **buffer**: The destination byte buffer into which to copy a null-terminated UTF8 representation of string. On return, buffer contains a UTF8 string representation of string. If bufferSize is too small, buffer will contain only partial results. If buffer is not at least bufferSize bytes in size, behavior is undefined.
  ## * **bufferSize**: The size of the external buffer in bytes.
  ## * **returns**: The number of bytes written into buffer (including the null-terminator byte).
  ## 

proc `==`*(a: JSStringRef, b: JSStringRef): bool {.importc: "JSStringIsEqual".}
  ## Tests whether two JavaScript strings match.
  ## 
  ## * **a**: The first JSString to test.
  ## * **b**: The second JSString to test.
  ## * **returns**:       true if the two strings match, otherwise false.
  ## 

proc `==`*(a: JSStringRef, b: cstring): bool {.importc: "JSStringIsEqualToUTF8CString".}
  ## Tests whether a JavaScript string matches a null-terminated UTF8 string.
  ## 
  ## * **a**: The JSString to test.
  ## * **b**: The null-terminated UTF8 string to test.
  ## * **returns**: true if the two strings match, otherwise false.
  ## 

#
# JSTypedArray
#

proc makeTypedArray*(ctx: JSContextRef, arrayType: JSType, length: csize_t, exception: JSException): JSObjectRef {.importc: "JSObjectMakeTypedArray".}
  ## Creates a JavaScript Typed Array object with the given number of elements.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **arrayType**: A value identifying the type of array to create. If arrayType is kJSType_dArrayTypeNone or kJSType_dArrayTypeArrayBuffer then `nil` will be returned.
  ## * **length**: The number of elements to be in the new Typed Array.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a Typed Array with all elements set to zero or `nil` if there was an error.

proc makeTypedArrayWithBytesNoCopy*(ctx: JSContextRef, arrayType: JSTypedArrayType, bytes: pointer, byteLength: csize_t, bytesDeallocator: JSTypedArrayBytesDeallocator, deallocatorContext: pointer, exception: JSException): JSObjectRef {.importc: "JSObjectMakeTypedArrayWithBytesNoCopy".}
  ## Creates a JavaScript Typed Array object from an existing pointer.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **arrayType**: A value identifying the type of array to create. If arrayType is kJSType_dArrayTypeNone or kJSType_dArrayTypeArrayBuffer then `nil` will be returned.
  ## * **bytes**: A pointer to the byte buffer to be used as the backing store of the Typed Array object.
  ## * **byteLength**: The number of bytes pointed to by the parameter bytes.
  ## * **bytesDeallocator**: The allocator to use to deallocate the external buffer when the JSType_dArrayData object is deallocated.
  ## * **deallocatorContext**: A pointer to pass back to the deallocator.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ Typed Array whose backing store is the same as the one pointed to by bytes or `nil` if there was an error.
  ## 
  ## If an exception is thrown during this function the bytesDeallocator will always be called.

proc makeTypedArrayWithArrayBuffer*(ctx: JSContextRef, arrayType: JSTypedArrayType, buffer: JSObjectRef, exception: JSException): JSObjectRef {.importc: "JSObjectMakeTypedArrayWithArrayBuffer".}
  ## Creates a JavaScript Typed Array object from an existing JavaScript Array Buffer object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **arrayType**: A value identifying the type of array to create. If arrayType is kJSType_dArrayTypeNone or kJSType_dArrayTypeArrayBuffer then `nil` will be returned.
  ## * **buffer**: An Array Buffer object that should be used as the backing store for the created JavaScript Typed Array object.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a Typed Array or `nil` if there was an error. The backing store of the Typed Array will be buffer.

proc makeTypedArrayWithArrayBuffer*(ctx: JSContextRef, arrayType: JSTypedArrayType, buffer: JSObjectRef, byteOffset: csize_t, length: csize_t, exception: JSException): JSObjectRef {.importc: "JSObjectMakeTypedArrayWithArrayBufferAndOffset".}
  ## Creates a JavaScript Typed Array object from an existing JavaScript Array Buffer object with the given offset and length.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **arrayType**: A value identifying the type of array to create. If arrayType is kJSType_dArrayTypeNone or kJSType_dArrayTypeArrayBuffer then `nil` will be returned.
  ## * **buffer**: An Array Buffer object that should be used as the backing store for the created JavaScript Typed Array object.
  ## * **byteOffset**: The byte offset for the created Typed Array. byteOffset should aligned with the element size of arrayType.
  ## * **length**: The number of elements to include in the Typed Array.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ that is a Typed Array or `nil` if there was an error. The backing store of the Typed Array will be buffer.

proc getTypedArrayBytesPtr*(ctx: JSContextRef, obj: JSObjectRef, exception: JSException): pointer {.importc: "JSObjectGetTypedArrayBytesPtr".}
  ## Returns a temporary pointer to the backing store of a JavaScript Typed Array object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The Typed Array object whose backing store pointer to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A pointer to the raw data buffer that serves as object's backing store or `nil` if object is not a Typed Array object.
  ## 
  ## The pointer returned by this function is temporary and is not guaranteed to remain valid across JavaScriptCore API calls.

proc getTypedArrayLength*(ctx: JSContextRef, obj: JSObjectRef, exception: JSException): csize_t {.importc: "JSObjectGetTypedArrayLength".}
  ## Returns the length of a JavaScript Typed Array object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The Typed Array object whose length to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The length of the Typed Array object or 0 if the object is not a Typed Array object.

proc getTypedArrayByteLength*(ctx: JSContextRef, obj: JSObjectRef, exception: ptr JSValueRef): csize_t {.importc: "JSObjectGetTypedArrayByteLength".}
  ## Returns the byte length of a JavaScript Typed Array object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The Typed Array object whose byte length to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The byte length of the Typed Array object or 0 if the object is not a Typed Array object.

proc getTypedArrayByteOffset*(ctx: JSContextRef, obj: JSObjectRef, exception: ptr JSValueRef): csize_t {.importc: "JSObjectGetTypedArrayByteOffset".}
  ## Returns the byte offset of a JavaScript Typed Array object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The Typed Array object whose byte offset to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The byte offset of the Typed Array object or 0 if the object is not a Typed Array object.

proc getTypedArrayBuffer*(ctx: JSContextRef, obj: JSObjectRef, exception: ptr JSValueRef): JSObjectRef {.importc: "JSObjectGetTypedArrayBuffer".}
  ## Returns the JavaScript Array Buffer object that is used as the backing of a JavaScript Typed Array object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JSObjectRef_ whose Typed Array type data pointer to obtain.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ with a JSType_dArrayType of kJSType_dArrayTypeArrayBuffer or `nil` if object is not a Typed Array.

proc makeArrayBufferWithBytesNoCopy*(ctx: JSContextRef, bytes: pointer, byteLength: csize_t, bytesDeallocator: JSTypedArrayBytesDeallocator, deallocatorContext: pointer, exception: JSException): JSObjectRef {.importc: "JSObjectMakeArrayBufferWithBytesNoCopy".}
  ## Creates a JavaScript Array Buffer object from an existing pointer.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **bytes**: A pointer to the byte buffer to be used as the backing store of the Typed Array object.
  ## * **byteLength**: The number of bytes pointed to by the parameter bytes.
  ## * **bytesDeallocator**: The allocator to use to deallocate the external buffer when the Typed Array data object is deallocated.
  ## * **deallocatorContext**: A pointer to pass back to the deallocator.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSObjectRef_ Array Buffer whose backing store is the same as the one pointed to by bytes or `nil` if there was an error.
  ## 
  ## If an exception is thrown during this function the bytesDeallocator will always be called.

proc getArrayBufferBytesPtr*(ctx: JSContextRef, obj: JSObjectRef, exception: JSException): pointer {.importc: "JSObjectGetArrayBufferBytesPtr".}
  ## Returns a pointer to the data buffer that serves as the backing store for a JavaScript Typed Array object.
  ## 
  ## * **obj**: The Array Buffer object whose internal backing store pointer to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A pointer to the raw data buffer that serves as object's backing store or `nil` if object is not an Array Buffer object.
  ## 
  ## The pointer returned by this function is temporary and is not guaranteed to remain valid across JavaScriptCore API calls.

proc getArrayBufferByteLength*(ctx: JSContextRef, obj: JSObjectRef, exception: JSException): csize_t {.importc: "JSObjectGetArrayBufferByteLength".}
  ## Returns the number of bytes in a JavaScript data object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **obj**: The JS Arary Buffer object whose length in bytes to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The number of bytes stored in the data object.

#
# JSValueRef
#

proc getTypeOf*(ctx: JSContextRef, value: JSValueRef): JSType {.importc: "JSValueGetType".}
  ## Returns a JavaScript value's type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue whose type you want to obtain.
  ## * **returns**: A value of type JSType_ that identifies value's type.

proc isUndefined*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsUndefined".}
  ## Tests whether a JavaScript value's type is the undefined type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the undefined type, otherwise false.

proc isNull*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsNull".}
  ## Tests whether a JavaScript value's type is the null type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the null type, otherwise false.

proc isBoolean*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsBoolean".}
  ## Tests whether a JavaScript value's type is the boolean type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the boolean type, otherwise false.

proc isNumber*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsNumber".}
  ## Tests whether a JavaScript value's type is the number type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the number type, otherwise false.

proc isString*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsString".}
  ## Tests whether a JavaScript value's type is the string type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the string type, otherwise false.

proc isSymbol*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsSymbol".}
  ## Tests whether a JavaScript value's type is the symbol type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the symbol type, otherwise false.

proc isObject*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsObject".}
  ## Tests whether a JavaScript value's type is the object type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value's type is the object type, otherwise false.

proc isObjOfClass*(ctx: JSContextRef, value: JSValueRef, jsClass: JSClassRef): bool {.importc: "JSValueIsObjectOfClass".}
  ## Tests whether a JavaScript value is an object with a given class in its class chain.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **jsClass**: The JSClass to test against.
  ## * **returns**: true if value is an object and has jsClass in its class chain, otherwise false.

proc isArray*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsArray".}
  ## Tests whether a JavaScript value is an array.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value is an array, otherwise false.

proc isDate*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueIsDate".}
  ## Tests whether a JavaScript value is a date.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **returns**: true if value is a date, otherwise false.

proc getTypedArrayType*(ctx: JSContextRef, value: JSValueRef, exception: JSException): JSTypedArrayType {.importc: "JSValueGetTypedArrayType".}
  ## Returns a JavaScript value's Typed Array type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue whose Typed Array type to return.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A value of type JSType_dArrayType that identifies value's Typed Array type, or kJSType_dArrayTypeNone if the value is not a Typed Array object.

proc isEqual*(ctx: JSContextRef, a: JSValueRef, b: JSValueRef, exception: JSException): bool {.importc: "JSValueIsEqual".}
  ## Tests whether two JavaScript values are equal, as compared by the JS == operator.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **a**: The first value to test.
  ## * **b**: The second value to test.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: true if the two values are equal, false if they are not equal or an exception is thrown.

proc isStrictEqual*(ctx: JSContextRef, a: JSValueRef, b: JSValueRef): bool {.importc: "JSValueIsStrictEqual".}
  ## Tests whether two JavaScript values are strict equal, as compared by the JS === operator.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **a**: The first value to test.
  ## * **b**: The second value to test.
  ## * **returns**: true if the two values are strict equal, otherwise false.

proc isInstanceOfConstructor*(ctx: JSContextRef, value: JSValueRef, constructor: JSObjectRef, exception: ptr JSValueRef): bool {.importc: "JSValueIsInstanceOfConstructor".}
  ## Tests whether a JavaScript value is an object constructed by a given constructor, as compared by the JS instanceof operator.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to test.
  ## * **constructor**: The constructor to test against.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: true if value is an object constructed by constructor, as compared by the JS instanceof operator, otherwise false.

proc makeUndefined*(ctx: JSContextRef): JSValueRef {.importc: "JSValueMakeUndefined".}
  ## Creates a JavaScript value of the undefined type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **returns**: The unique undefined value.

proc makeNull*(ctx: JSContextRef): JSValueRef {.importc: "JSValueMakeNull".}
  ## Creates a JavaScript value of the null type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **returns**: The unique null value.

proc makeBool*(ctx: JSContextRef, boolean: bool): JSValueRef {.importc: "JSValueMakeBoolean".}
  ## Creates a JavaScript value of the boolean type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **boolean**: The bool to assign to the newly created JSValue.
  ## * **returns**: A JSValue of the boolean type, representing the value of boolean.

proc makeNumber*(ctx: JSContextRef, number: cdouble): JSValueRef {.importc: "JSValueMakeNumber".}
  ## Creates a JavaScript value of the number type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **number**: The double to assign to the newly created JSValue.
  ## * **returns**: A JSValue of the number type, representing the value of number.

proc makeString*(ctx: JSContextRef, str: JSStringRef): JSValueRef {.importc: "JSValueMakeString".}
  ## Creates a JavaScript value of the string type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **str**: The JSString to assign to the newly created JSValue. The newly created JSValue retains string, and releases it upon garbage collection.
  ## * **returns**: A JSValue of the string type, representing the value of string.

proc makeSymbol*(ctx: JSContextRef, description: JSStringRef): JSValueRef {.importc: "JSValueMakeSymbol".}
  ## Creates a JavaScript value of the symbol type.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **description**: A description of the newly created symbol value.
  ## * **returns**: A unique JSValue of the symbol type, whose description matches the one provided.

proc makeFromJsonString*(ctx: JSContextRef, string: JSStringRef): JSValueRef {.importc: "JSValueMakeFromJSONString".}
  ## Creates a JavaScript value from a JSON formatted string.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **string**: The JSString containing the JSON string to be parsed.
  ## * **returns**: A JSValue containing the parsed value, or `nil` if the input is invalid.

proc createJsonString*(ctx: JSContextRef, value: JSValueRef, indent: cuint, exception: JSException): JSStringRef {.importc: "JSValueCreateJSONString".}
  ## Creates a JavaScript string containing the JSON serialized representation of a JS value.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The value to serialize.
  ## * **indent**: The number of spaces to indent when nesting.  If 0, the resulting JSON will not contains newlines.  The size of the indent is clamped to 10 spaces.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSString with the result of serialization, or `nil` if an exception is thrown.

proc toBool*(ctx: JSContextRef, value: JSValueRef): bool {.importc: "JSValueToBoolean".}
  ## Converts a JavaScript value to boolean and returns the resulting boolean.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to convert.
  ## * **returns**: The boolean result of conversion.

proc toNumber*(ctx: JSContextRef, value: JSValueRef, exception: JSException): cdouble {.importc: "JSValueToNumber".}
  ## Converts a JavaScript value to number and returns the resulting number.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to convert.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The numeric result of conversion, or NaN if an exception is thrown.

proc toString*(ctx: JSContextRef, value: JSValueRef, exception: JSException): JSStringRef {.importc: "JSValueToStringCopy".}
  ## Converts a JavaScript value to string and copies the result into a JavaScript string.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to convert.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: A JSString with the result of conversion, or `nil` if an exception is thrown. Ownership follows the Create Rule.

proc toObject*(ctx: JSContextRef, value: JSValueRef, exception: JSException): JSObjectRef {.importc: "JSValueToObject".}
  ## Converts a JavaScript value to object and returns the resulting object.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to convert.
  ## * **exception**: A pointer to a JSValueRef_ in which to store an exception, if any. Pass `nil` if you do not care to store an exception.
  ## * **returns**: The JSObjectRef_ result of conversion, or `nil` if an exception is thrown.

proc protect*(ctx: JSContextRef, value: JSValueRef): void {.importc: "JSValueProtect".}
  ## Protects a JavaScript value from garbage collection.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to protect.
  ## 
  ## Use this method when you want to store a JSValue in a global or on the heap, where the garbage collector will not be able to discover your reference to it.
  ##  
  ## A value may be protected multiple times and must be unprotected an equal number of times before becoming eligible for garbage collection.

proc unprotect*(ctx: JSContextRef, value: JSValueRef): void {.importc: "JSValueUnprotect".}
  ## Unprotects a JavaScript value from garbage collection.
  ## 
  ## * **ctx**: The execution context to use.
  ## * **value**: The JSValue to unprotect.
  ## 
  ## A value may be protected multiple times and must be unprotected an equal number of times before becoming eligible for garbage collection.

  
{.pop.}

proc `$`*(str: JSStringRef): string =
  ## Converts a JSStringRef_ to a nim string
  let length = str.len - 1
  var buf = newSeq[char](length)

  let bufLen = str.getCString(addr buf[0], length) - 1 # -1 to ignore null terminator
  result = newString(bufLen)
  for i in 0..<bufLen:
    result[i] = buf[i]
    
proc jsString*(str: cstring): JSStringRef {.inline.} = 
  ## Alias to `createJSString <#createJSString%2Ccstring>`
  createJSString(str)

# TODO, handle exceptions

proc toJSValue*(ctx: JSContextRef, val: string): JSValueRef
proc fromJSValue*[T: string](ctx: JSContextRef, val: JSValueRef, kind: typedesc[T]): T
proc getProperty*[T](ctx: JSContextRef, obj: JSObjectRef, propName: string, kind: typedesc[T]): T

proc setJSException*(ctx: JSContextRef, msg: string, exception: JSException) =
  ## Sets the exception pointer so that an exception is raised in the javascript context.
  ## Meant to be used when you have an exception pointer to set
  var jsMsg = ctx.toJSValue(msg)
  let err = ctx.makeError(1, addr jsMsg, nil)
  exception[] = cast[JSValueRef](err)

proc addToWindow*(ctx: JSContextRef, name: string, val: JSValueRef) =
  ## Adds a JSValueRef_ value to the global window object in the context so it can be 
  ## accessed from JS as if it was a global variable
  let name = createJSString name.cstring
  ctx.setProperty(ctx.globalObj, name, val, 0, nil)
  release name

proc addToWindow*(ctx: JSContextRef, vals: openArray[(string, JSValueRef)]) =
  ## Adds a key/value map of values to the window object
  for (name, val) in vals:
    ctx.addToWindow(name, val)

proc addToWindow*(ctx: JSContextRef, name: string, prc: JSObjectCallAsFunctionCallback) =
  ## Adds a function to the javascript context
  let cname = createJSString name
  let jsFun = cast[JSValueRef](ctx.makeFunctionWithCallback(cname, prc))
  ctx.addToWindow(name, jsFun)
  release cname



proc isNil*(val: JSValueRef | JSObjectRef): bool {.inline.} =
  result = val.JSPtr == nil


proc throwNim*(ctx: JSContextRef, exception: JSValueRef) =
  ## Throws a Nim exception from a `JSException` that has been returned from a proc
  assert not exception.isNil, "No exception has occured"
  # Stop showing off with "clever" code, make this less convoluted
  let 
    errMsg = ctx.getProperty(cast[JSObjectRef](exception), "message", string)
    errType = ctx.getProperty(cast[JSObjectRef](exception), "name", string)

  template doRaise(kind: untyped) = raise (ref kind)(msg: errMsg, orig: unsafeAddr exception)  

  # Make the error be more refined
  case errType
  of "ReferenceError":
    doRaise(JSReferenceError)
  of "RangeError":
    doRaise(JSRangeError)
  of "SyntaxError":
    doRaise(JSSyntaxError)
  of "TypeError":
    doRaise(JSTypeError)
  else:
    doRaise(JSError)
    
proc getProperty*(ctx: JSContextRef, obj: JSObjectRef, propName: string): JSValueRef =
  ## See `getProperty <#getProperty%2CJSContextRef%2CJSObjectRef%2CJSStringRef%2Cptr.JSValueRef>`_.
  var exception: JSValueRef
  let jsName = createJSString propName
  result = ctx.getProperty(obj, jsName, addr exception)
  if not exception.isNil:
    ctx.throwNim exception
    
  release jsName
  
proc getProperty*[T](ctx: JSContextRef, obj: JSObjectRef, propName: string, kind: typedesc[T]): T =
  ## Runs `getProperty <#getProperty%2CJSContextRef%2CJSObjectRef%2CJSStringRef%2Cptr.JSValueRef>`_ and then converts the property to `T`
  let jsVal = ctx.getProperty(obj, propName)
  result = ctx.fromJSValue(jsVal, kind)


#
# High level converters for conversion of Nim types to JSValueRefs
#

macro makeRaiser(prc: untyped) =
  ## Makes a version of a proc with the exception parameter removed and auto handles exceptions
  var
    exceptionIdent = ident"exception"
    newParams: seq[NimNode]
    inCall = nnkCall.newTree(prc.name) # Call to function that doesn't handle exception
  for i, param in prc.params:
    if i > 0:
      # If the parameter isn't the exception, then add it to the new procs parameters
      if not param[0].eqIdent("exception"):
        newParams &= param
        inCall &= ident $param[0]
      else:
        inCall &= nnkCommand.newTree(ident "unsafeAddr", exceptionIdent)
    else:
      # Add return type
      newParams &= param
    
  let body = quote do:
      var `exceptionIdent`: JSValueRef
      result = `inCall`
      if not `exceptionIdent`.isNil:
        ctx.throwNim `exceptionIdent`
        
  result = newStmtList(
    prc,
    newProc(
      prc[0],
      newParams,
      body
    )  
  )
  result[1][2] = prc[2] # Copy generic parameters

template expectType*(ctx: JSContextRef, val: JSValueRef, exception: JSException, kind: JSType, body: untyped) =
  ## Only runs body if **val** is of type **kind**.
  ## If it isn't then it raises a `ValueError` on the javascript side
  let valType = ctx.getTypeOf(val)
  if valType == kind:
    body
  else:
    ctx.setJSException("ValueError: Expected " & $kind & " but got " & $valType, exception)
    
proc makeJSClass[T: ref object](x: typedesc[T]): JSClassRef =
  ## .. Important:: You need to call makeJSClassWrapper_ first, this will give a compile time error if you don't
  {.error: "Call makeJSClass first".}

proc toJSValue*[T: SomeFloat | SomeInteger](ctx: JSContextRef, val: T): JSValueRef {.inline.} = 
  ## Converts a number into a JS value
  ctx.makeNumber(val.cdouble)

proc toJSValue*(ctx: JSContextRef, val: string): JSValueRef =
  let str = jsString(val.cstring)
  ctx.makeString(str) # We don't need to free str since the context will free it

proc toJSValue*[T: object](ctx: JSContextRef, val: T, exception: JSException, 
                           jsClass: JSClassRef = nil, data: pointer = nil): JSValueRef {.makeRaiser.} = 
  ## Converts an object into a JS object
  ## 
  ## * **jsClass**: The class to assign to the object, is the default class by default
  ## * **data**: Private data for the object, can be accessed with getPrivate_ later 
  let tmp = ctx.makeObject(jsClass, data)
  for name, value in val.fieldPairs():
    let key = createJSString(name)
    # TODO, make toJSValue use this procs exception pointer
    when compiles(ctx.toJSValue(value, exception)):
      let jsVal = ctx.toJSValue(value, exception)
      if exception[].isNil: return
    else:
      let jsVal = ctx.toJSValue(value)
      
    ctx.setProperty(tmp, key, jsVal, 0, exception)
    release key
    if not exception[].isNil:
      return
  result = cast[JSValueRef](tmp)

proc toJSValue*[T: ref object](ctx: JSContextRef, val: T): JSValueRef =
  ## Converts a ref object into a JS value. You must have called makeTypeWrapper_ on your type before calling this.
  ## ref objects sent across can have there values edited from javascript
  GC_ref(val)
  mixin makeJSClass
  result = cast[JSValueRef](ctx.makeObject(makeJSClass(T), cast[pointer](val)))

proc toJSValue*[T: JSValueRef](ctx: JSContextRef, val: T): JSValueRef {.inline.} = val
proc toJSValue*[T: JSObjectRef](ctx: JSContextRef, val: T): JSValueRef {.inline.} = cast[JSValueRef](val)

proc toJSValue*(ctx: JSContextRef, val: bool): JSValueRef {.inline.} =
  ## Converts a `bool` into a JSValue
  ctx.makeBool(val)


proc toJSValue*[T](ctx: JSContextRef, val: openArray[T], exception: JSException): JSValueRef {.makeRaiser.} =
  ## Converts items in a sequence into a JS array
  var items = newSeq[JSValueRef](val.len)
  for i, item in val:
    when compiles(ctx.toJSValue(item, exception)): 
      items[i] = ctx.toJSValue(item, exception)
      if not exception[].isNil:
        return
    else: 
      items[i] = ctx.toJSValue(item)

  result = cast[JSValueRef](ctx.makeArray(val.len.csize_t, addr items[0], exception))
  

proc toJSValue*(ctx: JSContextRef, val: DateTime, exception: JSException): JSValueRef {.makeRaiser.} =
  ## Converts a Nim `DateTime` into a JS `DateTime`
  var dateStr = ctx.toJSValue($val)
  result = cast[JSValueRef](ctx.makeDate(1, addr dateStr, exception))


#
# Converters from JS values
#
# Should danger turn off all exception checks?

# TODO: enums

proc fromJSValue*(ctx: JSContextRef, val: JSValueRef,
                  kind: typedesc[DateTime], exception: JSException): DateTime {.makeRaiser.} =
  ## Converts a JS date to a Nim Date
  ctx.expectType(val, exception, Object):
    let obj = cast[JSObjectRef](val)
    # Get the toISOString function
    let jsName = createJSString "toISOString"
    let isoFunc = cast[JSObjectRef](ctx.getProperty(obj, jsName, exception))
    release jsName
    if not exception[].isNil:
      return
    # Call the function
    let jsDateStr = ctx.callAsFunction(isoFunc, obj, 0, nil, exception)
    if not exception[].isNil:
      return
    let str = ctx.fromJSValue(jsDateStr, string, exception)
    result = str.parse("yyyy-MM-dd'T'hh:mm:ss'.'fff'Z'", tz=utc()).inZone(local())  

proc fromJSValue*[T: SomeInteger](ctx: JSContextRef, val: JSValueRef, 
                                  kind: typedesc[T], exception: JSException): T {.makeRaiser.} =
  ## Converts a JS number to a Nim number
  ctx.expectType(val, exception, Number):
    result = kind(ctx.toNumber(val, exception))
    
proc fromJSValue*[T: object](ctx: JSContextRef, val: JSValueRef, 
                             kind: typedesc[T], exception: JSException): T {.makeRaiser.} =
  ## Makes an `object` from a JSValue_
  ctx.expectType(val, exception, Object):
    let obj = ctx.toObject(val, exception)
    if not obj.isNil:
      for name, value in result.fieldPairs():
        let cName = createJSString(name)
        let jsVal = ctx.getProperty(obj, cName, exception)
        if not exception[].isNil:
          return
        release cName
        value = ctx.fromJSValue(jsVal, typeof(value), exception)
        if not exception[].isNil:
          return
      
proc fromJSValue*[T: ref object](ctx: JSContextRef, val: JSValueRef,
                                 kind: typedesc[T], exception: JSException): T {.makeRaiser.}=
  ## Gets a ref object from a value.
  ## Does this by accessing the private value
  ctx.expectType(val, exception, Object):
    let priv = cast[JSObjectRef](val).getPrivate()
    if priv.isNil:
      ctx.setJSException("Objects private pointer is not set to a ref object", exception)
    result = cast[T](priv)
  
proc fromJSValue*[T: string](ctx: JSContextRef, val: JSValueRef,
                             kind: typedesc[T], exception: JSException): T {.makeRaiser.} =
  ## Makes a `string` from a JSValue_
  ctx.expectType(val, exception, String):
    result = $ctx.toString(val, exception)
    
proc fromJSValue*(ctx: JSContextRef, val: JSValueRef, kind: typedesc[bool], 
                  exception: JSException): bool {.makeRaiser.}=
  ## Makes a `bool` from a JSValue_
  ctx.expectType(val, exception, Boolean):
    result = ctx.toBool(val)

template fromArrayLikeImpl(length: int) =
  ## Expects `exception` and `obj` to be declared in calling site
  for i in 0..<length:
    let jsVal = ctx.getPropertyAtIndex(obj, i.cuint, exception)
    if not exception[].isNil: return
    result[i] = ctx.fromJSValue(jsVal, T, exception)
    if not exception[].isNil: return

proc fromJSValue*[K: static[int], T](ctx: JSContextRef, val: JSValueRef, 
                                     kind: typedesc[array[K, T]], exception: JSException): array[K, T] {.makeRaiser.} =
  ## Makes an `array[T]`` from a JSValue_
  ctx.expectType(val, exception, Object):
    let obj = ctx.toObject(val, exception)
    if not exception[].isNil: return
    fromArrayLikeImpl(K)

proc fromJSValue*[T](ctx: JSContextRef, val: JSValueRef, 
                     kind: typedesc[seq[T]], exception: JSException): seq[T] {.makeRaiser.} =
  ## Makes a `seq[T]` from a JSValue_
  ctx.expectType(val, exception, Object):
    let obj = ctx.toObject(val, exception)
    if not exception[].isNil: return
    
    let length = ctx.fromJSValue(ctx.getProperty(obj, "length"), int, exception)
    if not exception[].isNil: return
    
    result = newSeq[T](length)
    fromArrayLikeImpl(length)



# TODO: Move to utils file
macro findProc*(choices: typed, signature: varargs[typed]): untyped =
  ## Used for narrowing a proc down when it has overloads
  runnableExamples:
    proc foo(a: string) = discard
    proc foo(a: int) = discard
    # We want to pass foo(int) to JS
    makeProcWrapper("fooJS", findProc(foo, int))

  if choices.kind == nnkSym:
    # Just return sym if it has no overloads
    return choices
    
  choices.expectKind(nnkClosedSymChoice)
  result = newEmptyNode()
  
  for choice in choices:
    var 
      index = 0
      found = true
    # Go through each parameter and see if the types line up with signature
    block newChoice:
      let impl = choice.getImpl()
      for param in impl[3][1..^1]:
        let kind = param[^2]
        for name in param[0 ..< ^2]:
          if not kind.eqIdent(signature[index]):
            found = false
            break newChoice
          inc index
          
    if found:
      return choice
  "Cannot find any overload that matches signature".error(choices)



type
  ClassParameter = object
    name, kind: NimNode
    attributes: set[JSPropertyAttribute]
    getter, setter: NimNode

proc makeSignature(params: openArray[(string, string)], returnType = ""): seq[NimNode] =
  ## Makes a sequence of NimNodes that can be passed to newProc 
  if returnType != "":
    result &= ident returnType

  for (name, kind) in params:
    result &= nnkIdentDefs.newTree(
      ident name,
      parseExpr(kind), # Makes handling types like UncheckedArray[T] easier
      newEmptyNode()
    )

macro makeTypeWrapper*(typ: typedesc[ref object], procs: varargs[typed]) =
  ## Makes a wrapper around a ref object so that it can be shared directly between Nim/JS code i.e. changing
  ## its values on the JS side affects the Nim side.
  ##
  ## It is recommended to use this for big objects since this is quicker than converting the entire object
  # Change interface to allow for more options e.g. make a constructor, add getter procs
  # TODO: Check if it is actually quicker
  # TODO: Optimise operations
  # TODO: Support oop (i.e. object of Something), maybe support this via JSClass inheritance also?
  let 
    impl = typ.getImpl()
    name = $impl[0]
  var body = impl[2]

  case body[0].kind
  of nnkSym:
    body = body[0].getImpl()[2]
  of nnkObjectTy:
    body = body[0]
  else: discard

  var params: seq[ClassParameter]    

  # TODO: Make this for loop into a util proc, I do it often enough
  # Extract all the types out of the type defintion (Making sure to following if its an alias)
  # Property attributes are found by seeing what pragmas are attached to the property
  for identDef in body[2]:
    let kind = identDef[^2]
    for param in identDef[0 ..< ^2]:
      block paramSect:
        var classParam = ClassParameter(attributes: {DontDelete}, kind: kind, setter: newNilLit())
        if param.kind == nnkPragmaExpr:
          classParam.name = param[0].extractName
          # Add options that relate to certain pragmas
          for prag in param[1]:
            if prag.eqIdent("jsHide"):
              # Ignore the property
              break paramSect
            elif prag.eqIdent("jsReadOnly"):
              classParam.attributes.incl ReadOnly
            elif prag.eqIdent("jsDontEnum"):
              classParam.attributes.incl DontEnum
        else:
          classParam.name = param.extractName
        params &= classParam

  let 
    pragmas = nnkPragma.newTree(ident "cdecl")
  result = newStmtList()
  
  # Forward declare the makeJSClass proc
  result.add: genAstOpt({kDirtyTemplate}, typ):
    proc makeJSClass*(obj: typedesc[typ]): JSClassRef

  # Create getters/setters
  var staticValues = nnkBracket.newTree()
  for parameter in params.mitems():
    # Idents need to be made every loop or I get capture errors
    # TODO: See if genasts will fix/help this
    let
      ctxIdent = ident "ctx"
      objIdent = ident "obj"
      exceptionIdent = ident "exception"
      valueIdent = ident "value"
      
      getterSig = makeSignature({
        $ctxIdent: "JSContextRef",
        $objIdent: "JSObjectRef",
        "propName": "JSStringRef",
        $exceptionIdent: "JSException"
      }, "JSValueRef")

      setterSig = makeSignature({
        $ctxIdent: "JSContextRef",
        $objIdent: "JSObjectRef",
        "propName": "JSStringRef",
        $valueIdent: "JSValueRef",
        $exceptionIdent: "JSException"
      }, "bool")
      
    let 
      getterName = genSym(nskProc, "get_" & $parameter.name)
      paramName = parameter.name
    # Create getter function
    let getterBody = quote do:
      var obje = cast[`typ`](`objIdent`.getPrivate())
      when compiles(ctx.toJSValue(obje.`paramName`, `exceptionIdent`[])):
        return ctx.toJSValue(obje.`paramName`, `exceptionIdent`[])
      else:
        return ctx.toJSValue(obje.`paramName`)
        
    result &= newProc(
      getterName,
      getterSig,
      getterBody,
      pragmas = pragmas
    )
    
    parameter.getter = getterName
    # Create setter if it is not ready only
    if ReadOnly notin parameter.attributes:
      let 
        setterName = genSym(nskProc, "set_" & $parameter.name)
        paramType = parameter.kind
        
      let setterBody = quote do:
        var obj = cast[`typ`](getPrivate `objIdent`)
        obj.`paramName` = ctx.fromJSValue(
                                `valueIdent`, 
                                typeof(obj.`paramName`),
                                `exceptionIdent`
                          )
        
        result = true

      result &= newProc(
        setterName,
        setterSig,
        setterBody,
        pragmas = pragmas
      )
      parameter.setter = setterName
      
    staticValues &= nnkObjConstr.newTree(
      ident "JSStaticValue",
      newColonExpr(ident "name", newLit $parameter.name),
      newColonExpr(ident "getProperty", parameter.getter),
      newColonExpr(ident "setProperty", parameter.setter),
      newColonExpr(ident "attributes", newLit parameter.attributes)
    )
    
  if staticValues.len > 0:
    # Static values need to end with a nil name
    staticValues &= nnkObjConstr.newTree(
      ident "JSStaticValue",
      newColonExpr(ident "name", newNilLit())
    )

  # Add all the functions that belong to the object
  var staticProcs = nnkBracket.newTree()
  for prc in procs:
    let impl = prc.getImpl()
    # if impl
    let name = $genSym(nskProc, $prc)
    let params = impl.parameters
    if not params[1].kind.eqIdent(typ):
      "First parameter must be the object for object procs".error(prc)
      
    staticProcs &= nnkObjConstr.newTree(
      ident "JSStaticFunction",
      newColonExpr(ident "name", newLit $name),
      newColonExpr(ident "callAsFunction", ident $name),
      newColonExpr(ident "attributes", newLit {ReadOnly, DontDelete})
    )
    result.add quote do:
      makeProcWrapper(`name`, `prc`, isObjFunc = true)
      
  if staticProcs.len > 0:
    # Static functions need to end with a nil name
    staticProcs &= nnkObjConstr.newTree(
      ident "JSStaticFunction",
      newColonExpr(ident "name", newNilLit())
    )

  let
    hasValues = staticValues.len > 0
    hasProcs = staticProcs.len > 0
    
  # Create final procs
  # Reason a proc is used is so that later converter procs can easily know if
  # a class version of an object exists
  let 
    finalizerIdent = genSym(nskProc, "finalizer")
    makeClassIdent = ident "makeJSClass"
  # Insert is needed since makeJSClass might be needed if any procs return the class
  result.add: genAstOpt({kDirtyTemplate}, hasValues = staticValues.len > 0, hasProcs = staticProcs.len > 0,
                     finalizer = genSym(nskProc, "finalizer"), name = name, typ = typ,
                     staticVals = staticValues, staticPrcs = staticProcs):
    proc finalizer(obj: JSObjectRef) {.cdecl.} =
      # Mark the object for garbage collection
      let obj = cast[typ](getPrivate obj)
      GC_unref(obj) # Or should I call `=destroy`?

    proc makeJSClass*(obj: typedesc[`typ`]): JSClassRef =
      var class {.global.}: JSClassRef
      once:
        var classDef = JSClassDefinitionEmpty
        # We use when statements since Nim cant infer the array if they are empty
        when hasValues:
          let tmpVals = staticVals
          classDef.staticValues = unsafeAddr tmpVals[0]

        when hasProcs:
          let tmpFuncs = staticPrcs
          classDef.staticFunctions = unsafeAddr tmpFuncs[0]

        classDef.className = name
        classDef.finalize = finalizer
        class = classCreate(addr classDef)
        
      result = class
      
macro makeProcWrapper*(name: static[string], prc: typed, ignoreArgs: static[bool] = false, isObjFunc: static[bool] = false, exportProc: static[bool] = true): untyped =
  ## Makes a wrapper around a native Nim proc so that it can be called from JS.
  ## The wrapper (which will be named **name**) will have the same signature as JSObjectCallAsFunctionCallback_
  ##
  ## * **name**: Name to give the generated proc
  ## * **ignoreArgs**: Whether to ignore the numbers of args passed in
  ## * **isObjFunc**: Make it true when making a function for an object `myObject.myFunction()` (Objects private data will be passed as the first parameter)
  ##
  ## .. Note:: This still needs to be registered to the context using addToWindow_
  # TODO: Allow for do syntax
  runnableExamples "-r:off":
    import std/db_sqlite
    let db = open(":memory:", "", "", "")

    proc runDB(query: string) =
      db.exec(sql(query))

    makeProcWrapper("runDBJS", runDB)

    var ctx: JSContextRef # DONT DO THIS, THIS IS JUST AN EXAMPLE
    ctx.addToWindow("runDB", runDBJS)
      
  if prc.kind == nnkClosedSymChoice:
    # Maybe print overloads also?
    "Proc passed has overloads, use `findProc` to narrow down to correct proc".error(prc)
    
  let impl = if prc.kind == nnkSym: prc.getImpl else: prc
  if impl.kind notin {nnkProcDef, nnkLambda}:
    "Expected a proc".error(prc)

  let 
    sym = impl[0]  
    paramsDecl = impl[3]

  var
    returnType = paramsDecl[0]
    params: seq[NimNode]
    call = nnkCall.newTree(sym)

  let
    ctxIdent = ident "ctx"
    argsIdent = ident "arguments"
    argCIdent = ident "argC"
    thisIdent = ident "this"
    exceptionIdent = ident "exception" # Exception that is passed in has a parameter from javascript
    expectedIdent = ident "expected"
    
  var 
    paramConv = newStmtList()
    index = 0
    insertedThisConv = false
  let 
    parameters = impl.parameters[1..^1]
    # We are expecting 1 less param if its an object function since that param
    # is passed from the `this` parameter
    parametersCount = parameters.len + (if isObjFunc: -1 else: 0)
  
  # Add a conversion of each parameter into a Nim type into the body
  # This converted variable will then be passed to the actual proc
  for param in parameters:
      if param.defaultValue.kind != nnkEmpty:
        "Default values are not supported".error(param.defaultValue)
        
      let 
        identName = ident param.name
        kind = ident $param.kind # Desym kind so it is passed has typedesc
      call &= identName
      if (not insertedThisConv) and isObjFunc:
        insertedThisConv = true
        let test = ident "fromJSValue"
        paramConv.add quote do:
          let `identName` = `ctxIdent`.`test`(cast[JSValueRef](`thisIdent`), `kind`, `exceptionIdent`)
          if not `exceptionIdent`[].isNil:
            return
         
      else:
        paramConv.add quote do:
          when compiles(`ctxIdent`.fromJSValue(`argsIdent`[`index`], `kind`, `exceptionIdent`)):
            let `identName` = `ctxIdent`.fromJSValue(`argsIdent`[`index`], `kind`, `exceptionIdent`)
            if not `exceptionIdent`[].isNil:
              return
          else:
            let `identName` = `ctxIdent`.fromJSValue(`argsIdent`[`index`], `kind`)
          
        inc index
  if returnType.kind != nnkEmpty:
    # Convert back to JS type is needed
    call = quote do:
      return `ctxIdent`.toJSValue(`call`)  
      
  let body = quote do:
    # Check that the correct amount of args are passed
    when not bool(`ignoreArgs`):
      if `argCIdent` != `parametersCount`: # Index will be same as count
        const `expectedIdent` = `parametersCount`
        ctx.setJSException(fmt"Invalid arg count, excepted {expected} but got {argC}", `exceptionIdent`)
    `paramConv`
    `call`
  # Signature of the proc that sent to the JS ctx
  let jsProcSig = makeSignature({
    $ctxIdent: "JSContextRef",
    "fun": "JSObjectRef",
    $thisIdent: "JSObjectRef",
    $argCIdent: "csize_t",
    $argsIdent: "UncheckedArray[JSValueRef]",
    $exceptionIdent: "JSException"
  }, returnType = "JSValueRef")


  var prcName = ident name
  if exportProc:
    prcName = nnkPostFix.newTree(ident "*", prcName)
    
  result = newProc(
    prcName,
    jsProcSig,
    body,
    pragmas = nnkPragma.newTree(
      ident "cdecl"
    )
  )

proc evalScript*(ctx: JSContextRef, script: string): JSValueRef = 
  ## Runs a script in the context and returns the result
  let scriptStr = createJSString script
  var exception: JSValueRef
  result = ctx.evalScript(
    scriptStr,
    nil,
    nil,
    1,
    addr exception
  )
  release scriptStr
  if not exception.isNil:
    ctx.throwNim exception
  

proc evalScript*[T](ctx: JSContextRef, script: string, retType: typedesc[T]): T = 
  ## Runs script and convert return value to a Nim type
  result = ctx.fromJSValue(ctx.evalScript(script), retType)



macro makeBinds*(procs: openArray[proc]) =
  ## Makes binding functions which can be added via addToWindow_.
  ## Generated procs have the same signature as JSObjectCallAsFunctionCallback_
  for prc in procs:
    echo prc.getImpl.treeRepr
