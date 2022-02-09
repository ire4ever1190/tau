import std/[strutils, os]
import std/[macros, macrocache]
import std/sugar

##
## This module contains types, procs, and helpers that are used throughout the files.
##
## Common with the types in this package is to have 4 versions. e.x. for App_
##
## * AppStrong_: Raw pointer that you have ownership over (you can call destroy on it)
## * AppWeak_: Raw pointer that you do not have ownership over (you cannot call destroy on it)
## * AppRaw_: Alias for both strong and weak version (used for procs that can take both)
## * App_: Nim object that wraps the pointer, used in the high level api (memory is automatically handled for it)
##
## The API is mostly consistent between low (except some functions are prefixed with `ul`) and high level (using the nim objects that wrap pointers) so it's recommended to use the high level api
## unless you have special reasons not to.
##
## * `wrap` is used to map a low level type/proc into a high level version
## * `pass` is used to convert a high level type into a low level type

const 
  headerFolder = currentSourcePath().parentDir() / "include"
  usingThreads = compileOption("threads")

const
  DLLAppCore*        = "libAppCore.so"
  DLLUltraLightCore* = "libUltralightCore.so"
  DLLUltraLight*     = "libUltralight.so"
  DLLWebCore*        = "libWebCore.so"


{.passL: "-lWebCore".}
{.passL: "-lUltralight".}
{.passL: "-lUltralightCore".}

{.passC: "-I" & headerFolder.}

const ultraLightVersion = "1.3.0" # Supported version

template cAPI(module: string): string = 
  ## Returns relative path to cAPI header for certain module
  headerFolder / module / "CAPI.h"


type 
  ULStruct* {.final, pure.} = object
  ULPtr* = ptr ULStruct
  
  Cursor* = enum
    Pointer = 0
    Cross
    Hand
    IBeam
    Wait
    Help
    EastResize
    NorthResize
    NorthEastResize
    NorthWestResize
    SouthResize
    SouthEastResize
    SouthWestResize
    WestResize
    NorthSouthResize
    EastWestResize
    NorthEastSouthWestResize
    NorthWestSouthEastResize
    ColumnResize
    RowResize
    MiddlePanning
    EastPanning
    NorthPanning
    NorthEastPanning
    NorthWestPanning
    SouthPanning
    SouthEastPanning
    SouthWestPanning
    WestPanning
    Move
    VerticalText
    Cell
    ContextMenu
    Alias
    Progress
    NoDrop
    Copy
    None
    NotAllowed
    ZoomIn
    ZoomOut
    Grab
    Grabbing
    Custom

  MessageSource* = enum
    XML = 0
    JS
    Network
    ConsoleAPI
    Storage
    AppCache
    Rendering
    CSS
    Security
    ContentBlocker
    Other

  MessageLevel* = enum
    Log = 1
    Warning = 2
    Error = 3
    Debug = 4
    Info = 5

  BitmapFormat* = enum
    ## **A8_UNORM**
    ##
    ## Alpha channel only, 8-bits per pixel.
    ##
    ## Encoding: 8-bits per channel, unsigned normalized.
    ##
    ## Color-space: Linear (no gamma), alpha-coverage only.
    ##
    ## **A8_UNORM_SRGB**
    ##
    ## Blue Green Red Alpha channels, 32-bits per pixel.
    ## 
    ## Encoding: 8-bits per channel, unsigned normalized.
    ##
    ## Color-space: sRGB gamma with premultiplied linear alpha channel.
    ##
    A8_UNORM
    A8_UNORM_SRGB
  KeyEventType* = enum
    ## * **KeyDown**: (Does not trigger accelerator commands in WebCore)
    ##
    ## .. Note: You should probably use RawKeyDown instead when a physical key
    ##        is pressed. This member is only here for historic compatibility
    ##        with WebCore's key event types.
    ##
    ## * **KeyUp**: Use this when a physical key is released  
    ## * **RawKeyDown** type. Use this when a physical key is pressed.
    ##
    ## .. Note: You should use RawKeyDown for physical key presses since it
    ##        allows WebCore to do additional command translation.
    ##
    ## * **Char**: Use this when the OS generates text from a physical key being pressed (eg, WM_CHAR on Windows).
    KeyDown
    KeyUp 
    RawKeyDown 
    Char

  MouseEventType* = enum
    MouseMoved
    MouseDown
    MouseUp

  MouseButton* {.pure.} = enum 
    None = 0
    Left
    Middle
    Right

  ScrollEventType* = enum
    ByPixel
    ByPage

  FaceWinding* = enum
    Clockwise
    CounterClockwise

  FontHinting* = enum
    ## **Smooth**
    ##
    ## Lighter hinting algorithm-- glyphs are slightly fuzzier but better
    ## resemble their original shape. This is achieved by snapping glyphs to the
    ## pixel grid only vertically which better preserves inter-glyph spacing.
    ##
    ## **Normal**
    ##
    ## Default hinting algorithm-- offers a good balance between sharpness and
    ## shape at smaller font sizes.
    ##
    ## **Monochrome**
    ##
    ## Strongest hinting algorithm-- outputs only black/white glyphs. The result
    ## is usually unpleasant if the underlying TTF does not contain hints for
    ## this type of rendering.
    Smooth
    Normal
    Monochrome

  WrapperObject*[T] = object
    ## Used to wrap a pointer for use in high level apis
    internal*: T

proc `=destroy`[T](obj: var WrapperObject[T]) =
  ## Destroys the object stored in the wrapper
  mixin destroy
  # Only destroy strong pointers
  when compiles(destroy obj.internal):
    if obj.internal != nil:
      destroy obj.internal
      obj.internal = nil
  else:
    # We don't want dangling pointers though
    obj.internal = nil

macro importType(kind: untyped, name: static[string] = "") =
  ## Creates four type definitions
  ##  - Strong: Pointer which can be destroyed
  ##  - Weak: Pointer which cannot be destroyed (usually it is handled by something else)
  ##  - Raw: A generic type for both strong and weak
  ##  - Wrapped: The pointer is wrapped in an object for use with destructors
  ## Strong, Weak, and Raw have respective prefixes (e.g. AppStrong, AppWeak, AppRaw)
  ## Using the both is fine for most cases for a parameter but the Weak and Strong types should be carefully choosen for each return type of
  ## a proc imported
  let
    typeIdent = ident(if name == "":  replace($kind, "UL", "") else: name)
    rawTypeIdent = ident $typeIdent & "Raw"
    strongIdent = ident $typeIdent & "Strong"
    weakIdent = ident $typeIdent & "Weak"
    cAPIName  = newStrLitNode $kind
  # Don't think the ptr ptr in the typedef matters
  result = quote do:
    type
      `strongIdent`* {.importc: `cAPIName`, pure, final.} = ptr ptr object
      `weakIdent`* {.importc: `cAPIName`, pure, final.} = ptr ptr object 
      `rawTypeIdent`* = `strongIdent` | `weakIdent`
      `typeIdent`* = WrapperObject[`rawTypeIdent`] | WrapperObject[`strongIdent`]


importType ULConfig
importType ULSettings
importType ULApp
importType ULMonitor
importType ULWindow
importType ULOverlay
importType ULView
importType ULRenderer
importType ULSession
importType ULViewConfig
importType ULBitmap
importType ULKeyEvent
importType ULMouseEvent
importType ULScrollEvent
importType ULSurface
importType ULBitmapSurface
importType(ULString, "ULString")



# Series of procs that aid in wrapping

proc wrap*[T: ptr ptr object](pointer: T): WrapperObject[T] {.inline.} =
  ## Wraps an UL object in a WrapperObject_
  result.internal = pointer

template wrap*(body: cuint): cuint = body

template wrap*(body: untyped) =
  ## No op, just returns the expression (useful if the thing getting wrapped returns void).
  ## Allows `wrap` to be used without worry
  body

template pass*(str: string | UlStringRaw): ULStringRaw =
  ## If `str` is a string then it is converted to a UlStringRaw_
  ## else its just passed directly
  mixin ulString
  when str is string:
    ulStringRaw str
  else:
    str

template pass*[T](obj: WrapperObject[T]): T =
  ## Passes the pointer stored in `obj`
  obj.internal

type ## Callbacks
  ResizeCallback*   = proc (data: pointer, width, height: cuint) {.nimcall, cdecl.}

type ## Aliases
  ULChar16* = cushort


macro importDestructor(kind: untyped, dll: string) =
  ## Import destructor from the c api and also creates a destructor for arc.
  ## Should only be used for strong pointers.
  ## The c destroy function is not exported since it doesn't make the pointer `nil` which causes problems later (leads to double destroy)
  ## so instead a template is exported which calls the c destuctor and makes the pointer nil
  let
    name = ($kind.toStrLit()).replace("UL", "")
    cName = "ulDestroy" & name.replace("Strong", "")
  result = quote do:
    proc destroy*(obj: `kind`) {.cdecl, importc: `cName`, dynlib: `dll`.}

when not defined(ulNoDestructors):
  importDestructor(SettingsStrong, DLLAppCore)
  importDestructor(ConfigStrong, DLLUltralight)
  importDestructor(WindowStrong, DLLAppCore)
  importDestructor(OverlayStrong, DLLAppCore)
  importDestructor(ULStringStrong, DLLUltralight)
  importDestructor(AppStrong, DLLAppCore)
  importDestructor(SessionStrong, DLLUltraLight)
  importDestructor(ViewConfigStrong, DLLUltraLight)
  importDestructor(BitmapStrong, DLLUltraLight)
  importDestructor(KeyEventStrong, DLLUltraLight)
  importDestructor(RendererStrong, DLLUltraLight)
  importDestructor(MouseEventStrong, DLLUltraLight)
  importDestructor(ScrollEventStrong, DLLUltraLight)



const wrapInfo = CacheTable"ultralightWrapInfo"

template setWrapInfo(header, dynlib: static[string]) =
  ## Should be called before using wrap macro.
  ## This sets the default header and dynlib for wrapping functions in the current file.
  bind wrapInfo
  bind `[]=`
  static:
    wrapInfo[instantiationInfo(fullPaths=true).filename] = newStmtList(
      newLit header,
      newLit dynlib
    )
  # Make pragma
  {.pragma: defC, dynlib: dynlib, header: header.}

proc deSym(node: NimNode) =
  ## Removes all

{.experimental: "flexibleOptionalParams".}

macro wrap(cName: static[string], prc: untyped): untyped =
  ## Wraps a low level proc by making a proc which uses the `WrapperObject` pointer to call it.
  ## This is meant for procs where the first param is the object.
  ## The procs are inlined with {.inline.}
  ## Use setWrapInfo_ first to set the info for the file
  ##
  ## While this is a chaotic macro, it generates code that otherwise would be very repeatitive and error prone
  let prcName = if prc[0].kind == nnkIdent:
      ident ($prc[0]).dup(removePrefix("ul"))
    else: # Means it is more complex like `name=`
      prc[0][^1]
  var 
    params = @[newEmptyNode()] # params to pass
    call = nnkCall.newTree(prcName)
  if prc.params[0].kind != nnkEmpty:
    params[0] = ident multiReplace($prc.params[0], {"Strong": "", "Weak": ""})
    
  var wasClassProc = false
  for i, node in prc.params[1..^1]:
    let paramType = node[^2]
    for param in node[0 ..< ^2]:
      var p = nnkIdentDefs.newTree( # Unbind the syms
        ident $param, # name
        ident $paramType, # type
        newEmptyNode()
      )
      if not wasClassProc and i > 0: break # don't process further
      # Perform conversions to allow easy types to be used e.g. (convert uint to int)
      let
        paramName = ident $p[0]
        typeName = toLowerAscii($p[1])

      if typeName == "ulstringraw":
        # Allow strings or raw strings to be passed to the proc,
        if i == 0:
          wasClassProc = true
        call &= nnkCall.newTree(
          ident "pass",
          p[0]
        )
        p[1] = nnkInfix.newTree(
          ident "|",
          ident "string",
          ident "ULString"
        )
      elif (typeName.endsWith("raw") or typeName.endsWith("strong") or typeName.endsWith("weak")):
        if i == 0:
          wasClassProc = true
        call &= nnkCall.newTree(
          ident "pass",
          ident $p[0]
        )
        p[1] = ident ($p[1]).replace("Raw", "")
      elif typeName.startsWith("c") and "int" in typeName:
        # Convert type e.g. int -> cint
        call &= nnkCall.newTree(
          ident typeName,
          paramName
        )
        p[1] = ident replace($p[1], "c", "") # Drop c from parameter e.g. cint -> int

      else:
        call &= ident $p[0]

      params &= p
  # Add pragmas to bind the proc to the c code correctly
  let filename = prc.lineInfoObj.filename
  prc.addPragma(newColonExpr(ident "dynlib", wrapInfo[filename][1]))
  prc.addPragma(newColonExpr(ident "header", wrapInfo[filename][0]))
  prc.addPragma(newColonExpr(ident "importc", newLit cName))

  result = newStmtList(
    prc
  )
  if wasClassProc:
    # Only automatically create a passing proc if the first parameter was an object.
    result &= newProc(
      name    = nnkPostFix.newTree(ident "*", prcName),
      params  = params,
      body    = newStmtList(nnkCall.newTree(ident "wrap", call)),
      pragmas = nnkPragma.newTree(
        ident "inline"
      )
    )
  #echo result.toStrLit
