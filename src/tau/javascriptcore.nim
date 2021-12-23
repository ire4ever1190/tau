import common

{.passL: "-lWebCore".}

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
  JSType*            = distinct JSPtr

  JSException*       = ptr JSValueRef
    ## Used to get the exception from a callback
  JSPropertyAttribute* {.pure.} = enum
    ## * **None**: Specifies that a property has no special attributes.
    ## * **ReadOnly**: Specifies that a property is read-only.
    ## * **DontEnum**: Specifies that a property should not be enumerated by JSPropertyEnumerators and JavaScript for...in loops.
    ## * **DontDelete**: Specifies that the delete operation should fail on a property.
    None       
    ReadOnly  
    DontEnum   
    DontDelete 
  JSClassAttribute* {.pure.} = enum
    ## * **None**: Specifies that a class has no special attributes. 
    ## * **NoAutomaticPrototype**: Specifies that a class should not automatically generate a shared prototype for its instance objects. Use kJSClassAttributeNoAutomaticPrototype in combination with JSObjectSetPrototype to manage prototypes manually.
    None                
    NoAutomaticPrototype

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
    ## * **attributes**: A bitset of JSPropertyAttribute_ to give to the property.
    name*: cstring
    getProperty*: JSObjectGetPropertyCallback
    setProperty*: JSObjectSetPropertyCallback
    attributes*: cint 

  JSStaticValueEx* {.bycopy, importc.} = object
    ## Extension of JSStaticValue* for use with class version 1000
    name*: cstring
    getProperty*: JSObjectGetPropertyCallbackEx
    setProperty*: JSObjectSetPropertyCallbackEx
    attributes*: cuint 

  JSStaticFunction* {.bycopy, importc.} = object
    ## This structure describes a statically declared function property.
    ##
    ## * **name**: A null-terminated UTF8 string containing the property's **name**:.
    ## * **callAsFunction**: A JSObjectCallAsFunctionCallback to invoke when the property is called as a function.
    ## * **attributes**: A logically ORed set of JSPropertyAttributes to give to the property.
    name*: cstring
    callAsFunction: JSObjectCallAsFunctionCallback
    attributes*: cuint

  JSStaticFunctionEx* {.bycopy, importc.} = object
    ## Extension of JSStaticFunction* for use with class version 1000
    name*: cstring
    callAsFunction: JSObjectCallAsFunctionCallbackEx
    attributes*: cuint


  JSClassCallbacks* {.bycopy, union.} = object
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
    
  JSClassCallbacksEx* {.bycopy, union.} = object
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

  JSClassCallbacksUnion* {.bycopy, union.} = object
    callbacks: JSClassCallbacks
    callbacksEx: JSClassCallbacksEx
    
  JSClassDefinition* {.bycopy, importc.} = object
    ## This structure contains properties and callbacks that define a type of object. All fields other than the version field are optional. Any pointer may be `nil`.
    ##
    ## The staticValues and staticFunctions arrays are the simplest and most efficient means for vending custom properties. Statically declared properties autmatically service requests like getProperty, setProperty, and getPropertyNames. Property access callbacks are required only to implement unusual properties, like array indexes, whose names are not known at compile-time.
    ## Standard JavaScript practice calls for storing function objects in prototypes, so they can be shared. The default JSClass created by JSClassCreate follows this idiom, instantiating objects with a shared, automatically generating prototype containing the class's function objects. The kJSClassAttributeNoAutomaticPrototype attribute specifies that a JSClass should not automatically generate such a prototype. The resulting JSClass instantiates objects with the default object prototype, and gives each instance object its own copy of the class's function objects.
    ## A `nil` callback specifies that the default object callback should substitute, except in the case of hasProperty, where it specifies that getProperty should substitute.
    ##
    ## * **version**: The version number of this structure. The current version is 0.
    ## * **attributes**: A bitset of JSClassAttributes_ to give to the class.
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
    attributes: cuint
    className*: cstring
    parentClass*: JSClassRef
    callbacks*: JSClassCallbacks
    privateData*: pointer

  
    
{.pop.}    

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
  ##
  ## **script**: A JSString containing the script to evaluate.
  ##
  ## **this**: The object to use as "this," or `nil` to use the global object as "this".
  ##
  ## **sourceURL**: A JSString containing a URL for the script's source file. This is used by debuggers and when reporting exceptions. Pass NULL if you do not care to include source file information.
  ##
  ## **startLineNumber**: An integer value specifying the script's starting line number in the file located at `sourceURL`. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ##
  ## **exception**: A pointer to a JSValueRef in which to store an exception, if any. Pass **nil** if you do not care to store an exception.
  ##
  ## **return**: The JSValue that results from evaluating script, or `nil` if an exception is thrown.

proc checkScriptSyntax*(ctx: JSContextRef, script, sourceURL: JSStringRef, startLineNumer: cint, exception: ptr JSValueRef): bool {.importc: "JSCheckScriptSyntax".}
  ## Checks for syntax errors in a string of JavaScript.
  ##
  ## **ctx**: The execution context to use.
  ##
  ## **script**: A JSString containing the **script** to check for syntax errors.
  ##
  ## **sourceURL**: A JSString containing a URL for the script's source file. This is only used when reporting exceptions. Pass `nil` if you do not care to include source file information in exceptions.
  ##
  ## **startingLineNumber**: An integer value specifying the script's starting line number in the file located at sourceURL. This is only used when reporting exceptions. The value is one-based, so the first line is line 1 and invalid values are clamped to 1.
  ##
  ## **exception**: A pointer to a JSValueRef in which to store a syntax error `exception`, if any. Pass `nil` if you do not care to store a syntax error exception.
  ##
  ## **return**: if the script is syntactically correct, otherwise false.

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

proc setPrivate*(jsClass: JSClassRef): bool {.importc: "JSClassSetPrivate".}
  ## Sets the private data on a class, only possible with classes created with version 1000 (extended callbacks).
  ##
  ## Only classes with version 1000 (extended callbacks) can store private data, for other classes the function always fails. The set pointer is not touched by the engine.
  ## 
  ## **jsClass**: The class to set the data on
  ## **data**: A pointer to set as the private data for the class
  ## **return**: true if the data has been set on the class, false if the class has not been created with version 1000 (extended callbacks)

proc makeObject*(ctx: JSContextRef, jsClass: JSClassRef, data: pointer): JSObjectRef {.importc: "JSObjectMake".}
  ## Creates a JavaScript object.
  ##
  ## The default object class does not allocate storage for private data, so you must provide a non-`nil` jsClass to JSObjectMake if you want your object to be able to store private data.
  ## data is set on the created object before the intialize methods in its class chain are called. This enables the initialize methods to retrieve and manipulate data through JSObjectGetPrivate.
  ## 
  ## **ctx**: The execution context to use.
  ## **jsClass**: The JSClass_ to assign to the object. Pass `nil` to use the default object class.
  ## **data**: A pointer to set as the object's private data. Pass `nil` to specify no private data.
  ## **return**: A JSObject_ with the given class and private data.

proc makeFunctionFromCallback*(ctx: JSContextRef, name: JSStringRef, function: JSObjectCallAsFunctionCallback): JSObjectRef {.importc: "JSObjectMakeFunctionWithCallback".}
  ## Convenience method for creating a JavaScript function with a given callback as its implementation.
  ##
  ## * **ctx**: The execution context to use.
  ## * **name**: A JSStringRef_ containing the function's name. This will be used when converting the function to string. Pass `nil` to create an anonymous function.
  ## * **function**: The JSObjectCallAsFunctionCallback_ to invoke when the function is called.
  ## * **return**: A JSObjectRef_ that is a function. The object's prototype will be the default function prototype.

proc makeConstructor(ctx: JSContextRef, jsClass: JSClassRef, constrc: JSObjectCallAsConstructorCallback): JSObjectRef {.importc: ""}

{.pop.}
