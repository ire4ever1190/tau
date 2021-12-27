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
    strongIdent = ident $typeIdent & "Strong"
    weakIdent = ident $typeIdent & "Weak"
    cAPIName  = newStrLitNode $kind
  result = quote do:
    type
      `strongIdent`* {.importc: `cAPIName`.} = distinct ULPtr
      `weakIdent`* {.importc: `cAPIName`.} = distinct ULPtr
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
    proc `destructorName`(`loweredName`: var `kind`) =
      when defined(logULDestroys):
        echo "Destroying: ", astToStr(`kind`) 
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
importDestructor(RendererStrong, DLLUltraLight)
importDestructor(MouseEventStrong, DLLUltraLight)
importDestructor(ScrollEventStrong, DLLUltraLight)
