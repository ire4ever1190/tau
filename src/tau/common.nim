import std/[strutils, macros, os]

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

# How does this work without headers?

type 
  ULStruct* {.final, pure.} = object
  ULPtr* = ptr ULStruct
  
  JSStruct* {.final, pure.} = object
  JSPtr* = ptr JSStruct
  
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
    A8_UNORM
    A8_UNORM_SRGB

  KeyEventType* = enum
    KeyDown
    KeyUp
    RawKeyDown
    Char

  MouseEventType* = enum
    MouseMoved
    MouseDown
    MouseUp

  MouseButton* = enum
    BtnNone = 0
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
    Smooth
    Normal
    Monochrome

  JSContextRef      = distinct JSPtr
  JSValueRef        = distinct JSPtr
  JSObjectRef       = distinct JSPtr
  JSStringRef       = distinct JSPtr
  JSClassDefinition = distinct JSPtr
  
  

macro importType(kind: untyped, name: static[string] = "") = 
  ## Creates three type definitions
  ##  - Strong: Pointer which can be destroyed
  ##  - Weak: Pointer which cannot be destroyed (usually it is handled by something else)
  ##  - Both: A generic type for both
  ## Strong and Weak have respective prefixes (e.g. AppStrong, AppWeak) while Both has none (e.g. App)
  ## Using the both is fine for most cases for a parameter but the Weak and Strong types should be carefully choosen for each return type of
  ## a proc imported
  echo name
  let 
    typeIdent = ident(if name == "":  replace($kind, "UL", "") else: name)
    strongIdent = ident $typeIdent & "Strong"
    weakIdent = ident $typeIdent & "Weak"
    cAPIName  = newStrLitNode $kind
  result = quote do:
    type
      `strongIdent`* {.importc: `cAPIName`.} = distinct ULPtr
      `weakIdent`* {.importc: `cAPIName`.} = distinct ptr ULStruct
      `typeIdent`* = `strongIdent` | `weakIdent`
      
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
  ## Should only be used for strong pointers
  let
    name = ($kind.toStrLit()).replace("UL", "")
    loweredName = ident name.toLowerAscii()
    cName = "ulDestroy" & name.replace("Strong", "")
    destructorName = nnkAccQuoted.newTree(ident"=destroy")
  result = quote do:
    proc destroy*(`loweredName`: `kind`) {.cdecl, importc: `cName`, dynlib: `dll`.}
    proc `destructorName`*(`loweredName`: var `kind`) =
      if `loweredName`.pointer != nil:
        destroy `loweredName`
        `loweredName` = nil    

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
importDestructor(MouseEventStrong, DllUltraLight)
importDestructor(ScrollEventStrong, DllUltraLight)
