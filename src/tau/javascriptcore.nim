import common

{.passL: "WebCore".}

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
  JSStringRef*       = distinct JSPtr
    ## A UTF16 character buffer. The fundamental string representation in JavaScript.
  JSClassDefinition* = distinct JSPtr
  JSType*            = distinct JSPtr

  JSException*       = ptr JSValueRef
    ## Used to get the exception from a callback
  JSPropertyAttribute* {.pure.} = enum
    None       ## Specifies that a property has no special attributes.
    ReadOnly   ## Specifies that a property is read-only.
    DontEnum   ## Specifies that a property should not be enumerated by JSPropertyEnumerators and JavaScript for...in loops.
    DontDelete ## Specifies that the delete operation should fail on a property.

  JSClassAttribute* {.pure.} = enum
    None                 ## Specifies that a class has no special attributes.
    NoAutomaticPrototype ## Specifies that a class should not automatically generate a shared prototype for its instance objects. Use kJSClassAttributeNoAutomaticPrototype in combination with JSObjectSetPrototype to manage prototypes manually.


type
  ObjectInitalizeCallback* = proc (ctx: JSContextRef, obj: JSObjectRef) {.nimcall, cdecl.}
      ## The callback invoked when an object is first created.
      ##
      ## Unlike the other object callbacks, the initialize callback is called on the least
      ## derived class (the parent class) first, and the most derived class last.
      ##
      ## **ctx**: The execution context to use.
      ##
      ## **obj**: The JSObject being created.

  ObjectInitalizeCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef) {.nimcall, cdecl.}
    ## Extension of ObjectInitalizeCallback_ with the class that the method is being invoked for.

  JSObjectFinalizeCallback* = proc (obj: JSObjectRef) {.nimcall, cdecl.}
    ## The callback invoked when an object is finalized (prepared for garbage collection). An object may be finalized on any thread.
    ##
    ## The finalize callback is called on the most derived class first, and the least 
    ## derived class (the parent class) last.
    ## You must not call any function that may cause a garbage collection or an allocation
    ## of a garbage collected object from within a JSObjectFinalizeCallback. This includes
    ## all functions that have a JSContextRef parameter.
    ##
    ## **obj**: The JSObject being finalized.

  JSObjectFinalizeCallbackEx* = proc (jsClass: JSClassRef, obj: JSObjectRef) {.nimcall, cdecl.}
   ## Extension of JSObjectFinalizeCallback_ with the class that the method is being invoked for.

  JSHasPropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef): bool {.nimcall, cdecl.}
    ## The callback invoked when determining whether an object has a property.
    ##
    ## If this function returns false, the hasProperty request forwards to object's statically declared properties, then its parent class chain (which includes the default object class), then its prototype chain.
    ## This callback enables optimization in cases where only a property's existence needs to be known, not its value, and computing its value would be expensive.
    ## If this callback is `nil`, the getProperty callback will be used to service hasProperty requests.
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **obj**: The JSObject to search for the property.
    ##
    ## **name**: A JSString containing the name of the property look up.
    ##
    ## **return**: true if object has the property, otherwise false.

  JSHasPropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef): bool {.nimcall, cdecl.}
    ## Extension of JSHasPropertyCallback_ with the class that the method is being invoked for.

  JSObjectGetPropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): JSvalueRef {.nimcall, cdecl.}
    ## The callback invoked when getting a property's value.
    ##
    ## If this function returns `nil`, the get request forwards to object's statically declared properties, then its parent class chain (which includes the default object class), then its prototype chain.
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **obj**: The JSObject to search for the property.
    ##
    ## **name**: A JSString containing the name of the property to get.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ##
    ## **return**: The property's value if object has the property, otherwise `nil`.

  JSObjectGetPropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectGetProperty_ with the class that the method is being invoked for.

  JSObjectSetPropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef, value: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## The callback invoked when setting a property's value.
    ##
    ## If this function returns false, the set request forwards to object's statically declared properties, then its parent class chain (which includes the default object class).
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **obj**: The JSObject on which to set the property's value.
    ##
    ## **name**: A JSString containing the name of the property to set.
    ##
    ## **value**: A JSValue to use as the property's value.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ##
    ## **return**: true if the property was set, otherwise false.

  JSObjectSetPropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef, value: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## Extension of JSObjectSetProperty_ with the class that the method is being invoked for.

  JSObjectDeletePropertyCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): bool {.nimcall, cdecl.}
    ## The callback invoked when deleting a property.
    ##
    ## If this function returns false, the delete request forwards to object's statically declared properties, then its parent class chain (which includes the default object class).
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **obj**: The JSObject in which to delete the property.
    ##
    ## **name**: A JSString containing the name of the property to delete.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ##
    ## **return**: true if propertyName was successfully deleted, otherwise false.

  JSObejctDeletePropertyCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, name: JSStringRef, exception: JSException): bool {.nimcall, cdecl.}
    ## Extension of JSObjectDeleteProperty_ with the class that the method is being invoked for.

  JSObjectGetPropertyNamesCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, names: JSPropertyNameAccumulatorRef) {.nimcall, cdecl.}
    ## The callback invoked when collecting the names of an object's properties.
    ##
    ## Property name accumulators are used by JSObjectCopyPropertyNames_ and JavaScript for...in loops. 
    ## Use JSPropertyNameAccumulatorAddName_ to add property names to accumulator. A class's `getPropertyNames` callback only needs to provide the names of properties that the class vends through a custom getProperty or setProperty callback. Other properties, including statically declared properties, properties vended by other classes, and properties belonging to object's prototype, are added independently.
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **object**: The JSObject whose property names are being collected.
    ##
    ## **names**: A JavaScript property name accumulator in which to accumulate the names of object's properties.

  JSObjectGetPropertyNamesCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, propertyNames: JSPropertyNameAccumulatorRef) {.nimcall, cdecl.}
    ## Extension of JSObjectGetPropertyNamesCallback_ with the class that the method is being invoked for.

  JSObjectCallAsFunctionCallback* = proc (ctx: JSContextRef, function, this: JSObjectRef, argumentCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.nimcall, cdecl}
    ## **JSObjectCallAsFunctionCallback**:
    ## The callback invoked when an object is called as a function.
    ##
    ## If your callback were invoked by the JavaScript expression 'myObject.myFunction()', `function` would be set to myFunction, and `this` would be set to myObject.
    ## If this callback is `nil`, calling your object as a function will throw an exception.
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **function**: A JSObject that is the function being called.
    ##
    ## **this**: A JSObject that is the `this` variable in the function's scope.
    ##
    ## **argumentCount**: An integer count of the number of arguments in arguments.
    ##
    ## **arguments**: A JSValue array of the arguments passed to the function.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ##
    ## **return**: A JSValue that is the function's return value.

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
    ## **ctx**: The execution context to use.
    ##
    ## **constructor**: A JSObject that is the constructor being called.
    ##
    ## **argumentCount**: An integer count of the number of arguments in arguments.
    ##
    ## **arguments**: A JSValue array of the arguments passed to the function.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an **exception**:, if any.
    ##
    ## **return**: A JSObject that is the constructor's return value.

  JSObjectCallAsConstructorCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, constrc: JSObjectRef, argumentCount: csize_t, arguments: UncheckedArray[JSValueRef], exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectCallAsConstructorCallback_ with the class that the method is being invoked for.

  JSObjectHasInstanceCallback* = proc (ctx: JSContextRef, target: JSobjectRef, possibleInstance: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## hasInstance The callback invoked when an object is used as the target of an 'instanceof' expression.
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **constructor**: The JSObject that is the target of the 'instanceof' expression.
    ##
    ## **possibleInstance**: The JSValue being tested to determine if it is an instance of constructor.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an exception, if any.
    ##
    ## **return**: true if possibleInstance is an instance of constructor, otherwise false.
    ##
    ## If your callback were invoked by the JavaScript expression 'someValue instanceof myObject', target would be set to `myObject` and possibleInstance would be set to `someValue`.
    ## If this callback is `nil`, 'instanceof' expressions that target your object will return false.
    ## Standard JavaScript practice calls for objects that implement the callAsConstructor callback to implement the hasInstance callback as well.

  JSObjectHasInstanceCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, target: JSobjectRef, possibleInstance: JSValueRef, exception: JSException): bool {.nimcall, cdecl.}
    ## Extension of JSObjectHasInstanceCallback_ with the class that the method is being invoked for.

  JSObjectConvertToTypeCallback* = proc (ctx: JSContextRef, obj: JSObjectRef, kind: JSType, exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## The callback invoked when converting an object to a particular JavaScript type.
    ##
    ## If this function returns false, the conversion request forwards to object's parent class chain (which includes the default object class).
    ## This function is only invoked when converting an object to number or string. An object converted to boolean is 'true.' An object converted to object is itself.
    ##
    ## **ctx**: The execution context to use.
    ##
    ## **object**: The JSObject to convert.
    ##
    ## **type**: A JSType specifying the JavaScript **type**: to convert to.
    ##
    ## **exception**: A pointer to a JSValueRef in which to return an **exception**:, if any.
    ##
    ## **return**: The objects's converted value, or `nil` if the object was not converted.

  JSObjectConvertToTypeCallbackEx* = proc (ctx: JSContextRef, jsClass: JSClassRef, obj: JSObjectRef, kind: JSType, exception: JSException): JSValueRef {.nimcall, cdecl.}
    ## Extension of JSObjectConvertToTypeCallback_ with the class that the method is being invoked for.
    
    

{.push header: "JavaScriptCore/JavaScript.h", dynlib: DLLWebCore.} # Think this is the right dynamic lib

#
# JSBase.h
#

proc evalScript*(ctx: JSContextRef, script: JSStringRef, this: JSObjectRef, 
                sourceURL: JSStringRef, startLineNumber: cint, exception: ptr JSValueRef): JSValueRef {.importc: "JSEvaluateScript".}
  ## Evaluates a string of JavaScript.
  ## `evalScript <ultralight.html#evalScript%2CView%2CULString%2Cptr.ULStringWeak>`_ Can be used instead to evaluate directly against a view
  ##
  ## **ctx**: The execution context to use.
  ## **script**: A JSString containing the script to evaluate.
  ## **this**: The object to use as "this," or `nil` to use the global object as "this".
  ## **sourceURL**: A JSString containing a URL for the script's source file. This is used by debuggers and when reporting exceptions. Pass NULL if you do not care to include source file information.
  ## **startLineNumber**: An integer value specifying the script's starting line number in the file located at `sourceURL`. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ## **exception**: A pointer to a JSValueRef in which to store an exception, if any. Pass **nil** if you do not care to store an exception.
  ## **result**: The JSValue that results from evaluating script, or `nil` if an exception is thrown.

proc checkScriptSyntax*(ctx: JSContextRef, script, sourceURL: JSStringRef, startLineNumer: cint, exception: ptr JSValueRef) {.importc: "JSCheckScriptSyntax".}
  ## Checks for syntax errors in a string of JavaScript.
  ##
  ## **ctx**: The execution context to use.
  ## **script**: A JSString containing the **script** to check for syntax errors.
  ## **sourceURL** A JSString containing a URL for the script's source file. This is only used when reporting exceptions. Pass `nil` if you do not care to include source file information in exceptions.
  ## **startingLineNumber**: An integer value specifying the script's starting line number in the file located at sourceURL. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ## **exception**: A pointer to a JSValueRef in which to store a syntax error `exception`, if any. Pass `nil` if you do not care to store a syntax error `exception`.
  ## **true**: if the script is syntactically correct, otherwise false.

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

# Don't know if these needs to be wrapped so leaving out until I find its needed

#
# JSObjectRef.h
#



{.pop.}
