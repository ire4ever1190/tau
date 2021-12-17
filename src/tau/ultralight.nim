import common
import ptr_math

{.passL: "-lUltralight".}

const headerFile = "<Ultralight/CAPI.h>"

when defined(windows):
  type ULFileHandle = distinct csize_t
else:
  type ULFileHandle = distinct cint

type
  Rect* {.bycopy.} = object
    left*: cfloat
    top*: cfloat
    right*: cfloat
    bottom*: cfloat

  IntRect* {.bycopy.} = object
    left*:   cint
    top*:    cint
    right*:  cint
    bottom*: cint
    
  RenderTarget* {.bycopy.} = object
    is_empty*: bool
    width*: cuint
    height*: cuint
    texture_id*: cuint
    texture_width*: cuint
    texture_height*: cuint
    texture_format*: BitmapFormat
    uv_coords*: Rect
    render_buffer_id*: cuint

  LogLevel* = enum
    Error = 0
    Warning
    Info

  Surface*     = distinct ULPtr
  BitmapSurface* = distinct Surface
  
{.push cdecl.} # Only pushing cdecl seems to work
type
  ChangeTitleCallback*       = proc (data: pointer, caller: ViewWeak, title: ULStringWeak) {.nimcall.}
  ChangeURLCallback*         = proc (data: pointer, caller: ViewWeak, url: ULStringWeak) {.nimcall.}
  ChangeTooltipCallback*     = proc (data: pointer, caller: ViewWeak, tooltip: ULStringWeak) {.nimcall.}
  ChangeCursorCallback*      = proc (data: pointer, caller: ViewWeak, cursor: Cursor) {.nimcall.}
  AddConsoleMessageCallback* = proc (data: pointer, caller: ViewWeak, source: MessageSource,
                                     lvl: MessageLevel, message: ULStringWeak, lineNum, colNum: cuint, 
                                     sourceID: ULStringWeak) {.nimcall.}
  CreateChildViewCallback*   = proc (data: pointer, caller: ViewWeak, openerURL, target: ULStringWeak,
                                     isPopup: bool, popupRect: IntRect) {.nimcall.}
  BeginLoadingCallback*      = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  FinishLoadingCallback*     = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  FailLoadingCallback*       = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool,
                                     url, description, errorDomain: ULStringWeak, errorCode: cint) {.nimcall.}
  WindowObjectReadyCallback* = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  DOMReadyCallback*          = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  UpdateHistoryCallback*     = proc (data: pointer, caller: ViewWeak) {.nimcall.}
  LoggerMessageCallback*     = proc (logLevel: LogLevel, msg: ULStringWeak) {.nimcall.}
{.pop.}

type
  ULLogger {.importc, header: headerFile.} = object
    log_message: LoggerMessageCallback

{.push dynlib: DLLUltraLight, header: headerFile.}

#
# Version info
#

proc versionString*(): cstring {.importc: "ulVersionString".}
proc versionMajor*(): cuint {.importc: "ulVersionMajor".}
proc versionMinor*(): cuint {.importc: "ulVersionMinor".}
proc versionPatch*(): cuint {.importc: "ulVersionPatch".}

#
# String
#
  
proc ulString*(str: cstring): ULStringStrong {.importc: "ulCreateString".}
proc ulString*(str: cstring, len: csize_t): ULStringStrong {.importc: "ulCreateStringUTF8".}
proc ulString*(str: ptr ULChar16, len: csize_t): ULStringStrong {.importc: "ulCreateStringUTF16".}
proc copy*(str: ULString): ULStringStrong {.importc: "ulCreateStringFromCopy".}
proc `copy=`*(dest: var ULStringStrong, src: ULString) =
  if dest.pointer != src.pointer:
    `=destroy`(dest)
    wasMoved(dest)
    dest = copy src
proc len*(str: ULString): cint {.importc: "ulStringGetLength".}
proc data*(str: ULString): ptr ULChar16 {.importc: "ulStringGetData".}
proc isEmpty*(str: ULString): bool {.importc: "ulStringIsEmpty".}
# TODO: allow these assigns to be used with `=` operator
proc assign*(str: ULString, newStr: ULString) {.importc: "ulStringAssignString".}
proc assign*(str: ULString, newStr: cstring) {.importc: "ulStringAssignCString".}

#
# Bitmap
#

proc createEmptyBitmap*(): BitmapStrong {.importc: "ULBitmap".}
proc createBitmap*(width, height: cuint, format: BitmapFormat): BitmapStrong {.importc: "ulCreateBitmap".}
proc createBitmap*(width, height: cuint, format: BitmapFormat, 
                   rowBytes: cuint, pixels: pointer, size: csize_t, shouldCopy: bool): BitmapStrong {.importc: "ulCreateBitmapFromPixels".}
proc copy*(bitmap: Bitmap): BitmapStrong {.importc: "ulCreateBitmapFromCopy".}
proc `copy=`*(dest: var BitmapStrong, src: Bitmap) =
  if dest.pointer != src.pointer:
    `=destroy`(dest)
    wasMoved(dest)
    dest = copy src

proc width*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetWidth".}
proc height*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetHeight".}
proc format*(bitmap: Bitmap): BitmapFormat {.importc: "ulBitmapGetFormat".}
proc bpp*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetBpp".}
proc rowBytes*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetRowBytes".}
proc len*(bitmap: Bitmap): csize_t {.importc: "ulBitmapGetSize".}
proc ownsPixels*(bitmap: Bitmap): bool {.importc: "ulBitmapOwnsPixels".}
proc lockPixels*(bitmap: Bitmap): pointer {.importc: "ulBitmapLockPixels".}
proc unlockPixels*(bitmap: Bitmap) {.importc: "ulBitmapUnlockPixels".}
proc rawPixels*(bitmap: Bitmap) {.importc: "ulBitmapRawPixels".}
proc isEmpty*(bitmap: Bitmap): bool {.importc: "ulBitmapIsEmpty".}
proc erase*(bitmap: Bitmap) {.importc: "ulBitmapErase".}
proc writePNG*(bitmap: Bitmap, path: cstring) {.importc: "ulBitmapWritePNG".}
proc swapRedBlueChannels*(bitmap: Bitmap) {.importc: "ulBitmapSwapRedBlueChannels".}

#
# Mouse/Key/Scroll Events
#

proc createKeyEvent*(kind: KeyEventType, modifiers: cuint, virtualKeyCode, nativeKeyCode: cint,
                     text, unmodifiedText: ULString,
                     isKeypad, isAutoRepeat, isSystemKey: bool) {.importc: "ulCreateKeyEvent".}

proc createMouseEvent*(kind: MouseEventType, x, y: cint, button: MouseButton) {.importc: "ulCreateMouseEvent".}
proc createScrollEvent*(kind: ScrollEventType, deltaX, deltaY: cint) {.importc: "ulCreateScrollEvent".}

# TODO: Add apis for making key events from native win32/mac key events

#
#  Rect/IntRect
#

proc isEmpty*(rect: Rect): bool {.importc: "ulRectIsEmpty".}
proc makeEmptyRect*(): Rect {.importc: "ulRectMakeEmpty".}

proc isEmpty*(rect: IntRect): bool {.importc: "ulIntRectIsEmpty".}
proc makeEmptyIntRect*(): IntRect {.importc: "ulIntRectMakeEmpty".}

#
# Surface
#

proc width*(surface: Surface): cuint {.importc: "ulSurfaceGetWidth".} 
proc height*(surface: Surface): cuint {.importc: "ulSurfaceGetHeight".} 
proc rowBytes*(surface: Surface): cuint {.importc: "ulSurfaceGetRowBytes".}
proc len*(surface: Surface): csize_t {.importc: "ulSurfaceGetSize".}
proc lockPixels*(surface: Surface): pointer {.importc: "ulSurfaceLockPixels".}
proc unlockPixels*(surface: Surface) {.importc: "ulSurfaceUnlockPixels".}
proc resize*(surface: Surface, width, height: cuint) {.importc: "ulSurfaceResize".}
proc `dirtyBounds=`*(surface: Surface, bounds: IntRect) {.importc: "ulSurfaceSetDirtyBounds".}
proc dirtyBounds*(surface: Surface): IntRect {.importc: "ulSurfaceGetDirtyBounds".}
proc clearDirtyBounds*(surface: Surface) {.importc: "ulSurfaceClearDirtyBounds".}
proc userData*(surface: Surface): pointer {.importc: "ulSurfaceGetUserData".}

proc bitmap*(surface: BitmapSurface) {.importc: "ulBitmapSurfaceGetBitmap".}

#
# Config
#
  
proc createConfig*(): ConfigStrong {.importc: "ulCreateConfig".}
proc `resourcePath=`*(config: Config, path: ULString) {.importc: "ulConfigSetResourcePath".}
proc `cachePath=`*(config: Config, path: ULString) {.importc: "ulConfigSetCachePath".}

#
# View
#

proc title*(view: View): ULStringWeak {.importc: "ulViewGetTitle".}
proc url*(view: View): ULStringWeak {.importc: "ulViewGetURL".}
proc width*(view: View): cuint {.importc: "ulViewGetWidth".}
proc height*(view: View): cuint {.importc: "ulViewGetHeight".}
proc resize*(view: View, width, height: cuint) {.importc: "ulViewResize".}
proc isLoading*(view: View): bool {.importc: "ulViewIsLoading".}
proc renderTarget*(view: View): RenderTarget {.importc: "ulViewGetRenderTarget".}
proc surface*(view: View): Surface {.importc: "ulViewGetSurface".}

proc loadURL*(view: View, url: ULString) {.importc: "ulViewLoadURL".}
proc loadHTML*(view: View, html: ULString) {.importc: "ulViewLoadHTML".}

proc lockJSCtx*(view: View) {.importc: "ulViewLockJSContext".}
proc unlockJSCtx*(view: View) {.importc: "ulViewUnlockJSContext".}
proc evalScript*(view: View, js: ULString, exception: ptr ULStringStrong) {.importc: "ulViewEvaluateScript".}

proc canGoBack*(view: View): bool {.importc: "ulViewCanGoBack".}
proc canGoForward*(view: View): bool {.importc: "ulViewCanGoForward".}
proc goBack*(view: View) {.importc: "ulViewGoBack".}
proc goForward*(view: View) {.importc: "ulViewGoForward".}
proc gotoHistoryOffset*(view: View, offset: cint) {.importc: "ulViewGoToHistoryOffset".}

proc reload*(view: View) {.importc: "ulViewReload".}
proc stop*(view: View) {.importc: "ulViewStop".}

proc focus*(view: View) {.importc: "ulViewFocus".}
proc unfocus*(view: View) {.importc: "ulViewUnfocus".}
proc hasFocus*(view: View): bool {.importc: "ulViewHasFocus".}
proc hasInputFocus*(view: View): bool {.importc: "ulViewHasInputFocus".}

proc fireEvent*(view: View, event: KeyEvent) {.importc: "ulViewFireKeyEvent".}
proc fireEvent*(view: View, event: MouseEvent) {.importc: "ulViewFireMouseEvent".}
proc fireEvent*(view: View, event: ScrollEvent) {.importc: "ulViewFireScrollEvent".}

proc setChangeTitleCallback*(view: View, callback: ChangeTitleCallback, data: pointer) {.importc: "ulViewSetChangeTitleCallback".}
proc setChangeURLCallback*(view: View, callback: ChangeURLCallback, data: pointer) {.importc: "ulViewSetChangeURLCallback".}
proc setChangeTooltipCallback*(view: View, calback: ChangeTooltipCallback, data: pointer) {.importc: "ulViewSetChangeTooltipCallback".}
proc setChangeCursorCallback*(view: View, callback: ChangeCursorCallback, data: pointer) {.importc: "ulViewSetChangeCursorCallback".}
proc setAddConsoleMessageCallback*(view: View, callback: AddConsoleMessageCallback, data: pointer) {.importc: "ulViewSetAddConsoleMessageCallback".}
proc setCreateChildViewCallback*(view: View, callback: CreateChildViewCallback, data: pointer) {.importc: "ulViewSetCreateChildViewCallback".}
proc setBeginLoadingCallback*(view: View, callback: BeginLoadingCallback, data: pointer) {.importc: "ulViewSetBeginLoadingCallback".}
proc setFinishLoadingCallback*(view: View, callback: FinishLoadingCallback, data: pointer) {.importc: "ulViewSetFinishLoadingCallback".}
proc setFailLoadingCallback*(view: View, callback: FailLoadingCallback, data: pointer) {.importc: "ulViewSetFailLoadingCallback".}
proc setWindowObjectReadyCallback*(view: View, callback: WindowObjectReadyCallback, data: pointer) {.importc: "ulViewSetWindowObjectReadyCallback".}
proc setDOMReadyCallback*(view: View, callback: DOMReadyCallback, data: pointer) {.importc: "ulViewSetDOMReadyCallback".}
proc setUpdateHistoryCallback*(view: View, callback: UpdateHistoryCallback, data: pointer) {.importc: "ulViewSetUpdateHistoryCallback".}

proc `needsPaint=`*(view: View, needsPaint: bool) {.importc: "ulViewSetNeedsPaint".}
proc needsPaint*(view: View): bool {.importc: "ulViewGetNeedsPaint".}
proc createInspectorView*(view: View): ViewStrong {.importc: "ulViewCreateInspectorView".}


#
# Session
#

proc defaultSession*(renderer: Renderer): SessionWeak {.importc: "ulDefaultSession".}
proc isPersistent*(session: Session): bool {.importc: "ulSessionIsPersistent".}
proc name*(session: Session): ULStringWeak {.importc: "ulSessionGetName".}
proc id*(session: Session): culonglong {.importc: "ulSessionGetId".}
proc diskPath*(session: Session): ULStringWeak {.importc: "ulSessionGetDiskPath".}

#
# File System
#

#
# Platform
#

proc setDefaultLogger*(logger: ULLogger) {.importc: "ulPlatformSetLogger".}

#
# ViewConfig
#

proc createViewConfig*(): ViewConfigStrong {.importc: "ulCreateViewConfig".}
proc `accelerated=`*(config: ViewConfig, isAccelerated: bool) {.importc: "ulViewConfigSetIsAccelerated".}
proc `transparent=`*(config: ViewConfig, isTransparent: bool) {.importc: "ulViewConfigSetIsTransparent".}
proc `initialDeviceScale=`*(config: ViewConfig, initalScale: cdouble) {.importc: "ulViewConfigSetInitialDeviceScale".}
proc `initialFocus=`*(config: ViewConfig, isFocused: bool) {.importc: "ulViewConfigSetInitialFocus".}
proc `enableImages=`*(config: ViewConfig, enabled: bool) {.importc: "ulViewConfigSetEnableImages".}
proc `enableJS=`*(config: ViewConfig, enabled: bool) {.importc: "ulViewConfigSetEnableImages".}
proc `fontFamilyStandard=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilyStandard".}
proc `fontFamilyFixed=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilyFixed".}
proc `fontFamilySerif=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilySerif".}
proc `userAgent=`*(config: ViewConfig, agentString: ULString) {.importc: "ulViewConfigSetUserAgent".}

{.pop.}

proc `$`*(str: ULString): string =
  ## Converts an UltraLight string into a nim string
  var data = str.data
  result = newStringOfCap(str.len) 
  for i in 0..<str.len:
    result &= chr(data[])
    data += 1

proc echoLog(x: LogLevel, y: ULString) {.cdecl.} = 
  echo x, ": ", y



let echoLogger* = ULLogger(
  log_message: echoLog
)
