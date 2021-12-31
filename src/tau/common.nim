import std/[strutils, macros, os]

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
## The API is consistent between low (using the raw pointers) and high level (using the nim objects that wrap pointers) so it's recommended to use the high level api
## unless you have special reasons not to.

const headerFolder = currentSourcePath().parentDir() / "include"


const
  DLLAppCore*        = "libAppCore.so"
  DLLUltraLightCore* = "libUltralightCore.so"
  DLLUltraLight*     = "libUltralight.so"
  DLLWebCore*        = "libWebCore.so"

{.passC: "-I" & headerFolder.}

const ultraLightVersion = "1.2.0" # Supported version

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
    kMessageLevel_Log = 1
    kMessageLevel_Warning = 2
    kMessageLevel_Error = 3
    kMessageLevel_Debug = 4
    kMessageLevel_Info = 5

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
    internal: T

macro importType(kind: untyped, name: static[string] = "") = 
  ## Creates three type definitions
  ##  - Strong: Pointer which can be destroyed
  ##  - Weak: Pointer which cannot be destroyed (usually it is handled by something else)
  ##  - Both: A generic type for both
  ## Strong and Weak have respective prefixes (e.g. AppStrong, AppWeak) while Both has none (e.g. App)
  ## Using the both is fine for most cases for a parameter but the Weak and Strong types should be carefully choosen for each return type of
  ## a proc imported
  let 
    typeIdent = ident(if name == "":  replace($kind, "UL", "") else: name)
    rawTypeIdent = ident $typeIdent & "Raw"
    strongIdent = ident $typeIdent & "Strong"
    weakIdent = ident $typeIdent & "Weak"
    cAPIName  = newStrLitNode $kind
  result = quote do:
    type
      `strongIdent`* {.importc: `cAPIName`.} = distinct ULPtr
      `weakIdent`* {.importc: `cAPIName`.} = distinct ULPtr
      `rawTypeIdent`* = `strongIdent` | `weakIdent`
      # `typeIdent`* = WrapperObject[`strongIdent`]
      
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
importType(ULString, "ULString")

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
    loweredName = ident name.toLowerAscii()
    cName = "ulDestroy" & name.replace("Strong", "")
    destructorName = nnkAccQuoted.newTree(ident"=destroy")
    cDestructor = ident "ulDestroy"
  result = quote do:
    proc destroy*(`loweredName`: `kind`) {.cdecl, importc: `cName`, dynlib: `dll`.}


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

proc `=destroy`[T](obj: var WrapperObject[T]) =
  ## Destroys the object stored in the wrapper
  mixin destory
  if obj.internal != nil:
    destroy obj.internal
    obj.internal = nil


macro wrap[T](obj: typedesc[WrapperObject[T]], prc: proc) =
  ## Wraps a low level proc by making a proc which uses the `WrapperObject` pointer to call it.
  ## This is meant for procs where the first param is the object.
  ## The procs are inlined with {.inline.}
  let prcName = ident $prc
  var params: seq[NimNode]
  var call = nnkCall.newTree(
    prcName
  )
  for i, param in prc.getTypeImpl[0][1..^1]:
    var p = nnkIdentDefs.newTree( # Unbind the syms
      ident $param[0],
      ident $param[1],
      newEmptyNode()
    )
    # Perform conversions to allow easy types to be used e.g. (convert uint to int)
    let 
      paramName = ident $p[0]
      typeName = toLowerAscii($p[1])
      
    if typeName.endsWith("raw") or typeName.endsWith("strong") or typeName.endsWith("weak"):
      call &= nnkDotExpr.newTree(
        ident $p[0],
        ident "internal"
      ) 
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
    
    
  result = newProc(
    name    = prcName,
    params  = params,
    body    = newStmtList(call),
    pragmas = nnkPragma.newTree(
      ident "inline"
    )
  )
