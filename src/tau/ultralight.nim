import common
import ptr_math

{.passL: "-lUltralight".}

const headerFile = "<Ultralight/CAPI.h>"

when defined(windows):
  type ULFileHandle = distinct csize_t
else:
  type ULFileHandle = distinct cint

const invalidFileHande = ULFileHandle(-1)

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
                                     isPopup: bool, popupRect: IntRect): ViewWeak {.nimcall.}
  BeginLoadingCallback*      = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  FinishLoadingCallback*     = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  FailLoadingCallback*       = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool,
                                     url, description, errorDomain: ULStringWeak, errorCode: cint) {.nimcall.}
  WindowObjectReadyCallback* = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  DOMReadyCallback*          = proc (data: pointer, caller: ViewWeak, frameID: culonglong, mainFrame: bool, url: ULStringWeak) {.nimcall.}
  UpdateHistoryCallback*     = proc (data: pointer, caller: ViewWeak) {.nimcall.}
  LoggerMessageCallback*     = proc (logLevel: LogLevel, msg: ULStringWeak) {.nimcall.}
  # Surface definition callbacks
  SurfaceDefinitionCreateCallback*       = proc (width, height: cuint): pointer {.nimcall.}
  ## The callback invoked when a Surface is created.
  ##
  ## **width**  The width in pixels.
  ## **param**  height  The height in pixels.
  ##
  ##          This callback should return a pointer to user-defined data for the
  ##          instance. This user data pointer will be passed to all other
  ##          callbacks when operating on the instance.
  SurfaceDefinitionDestroyCallback*      = proc (data: pointer) {.nimcall.}
  SurfaceDefinitionGetWidthCallback*     = proc (data: pointer): cuint {.nimcall.}
  SurfaceDefinitionGetHeightCallback*    = proc (data: pointer): cuint {.nimcall.}
  SurfaceDefinitionGetRowBytesCallback*  = proc (data: pointer): cuint {.nimcall.}
  SurfaceDefinitionGetSizeCallback*      = proc (data: pointer): csize_t {.nimcall.}
  SurfaceDefinitionLockPixelsCallback*   = proc (data: pointer): pointer {.nimcall.}
  SurfaceDefinitionUnlockPixelsCallback* = proc (data: pointer) {.nimcall.}
  SurfaceDefinitionResizeCallback*       = proc (data: pointer, width, height: cuint) {.nimcall.}
  
  
{.pop.}

type
  ULLogger* {.importc, header: headerFile.} = object
    log_message*: LoggerMessageCallback

  ULSurfaceDefinition* {.importc, header: headerFile.} = object
    create*: SurfaceDefinitionCreateCallback
    destroy*: SurfaceDefinitionDestroyCallback
    get_width*: SurfaceDefinitionGetWidthCallback
    get_height*: SurfaceDefinitionGetHeightCallback
    get_row_bytes*: SurfaceDefinitionGetRowBytesCallback
    get_size*: SurfaceDefinitionGetSizeCallback
    lock_pixels*: SurfaceDefinitionLockPixelsCallback
    unlock_pixels*: SurfaceDefinitionUnlockPixelsCallback
    resize*: SurfaceDefinitionResizeCallback

{.push dynlib: DLLUltraLight, header: headerFile.}

#
# Version info
#

proc versionString*(): cstring {.importc: "ulVersionString".}
  ## Get the version string of the library in MAJOR.MINOR.PATCH format.
proc versionMajor*(): cuint {.importc: "ulVersionMajor".}
  ## Get the numeric major version of the library.
proc versionMinor*(): cuint {.importc: "ulVersionMinor".}
  ## Get the numeric minor version of the library.
proc versionPatch*(): cuint {.importc: "ulVersionPatch".}
  ## Get the numeric patch version of the library.
  

#
# String
#
  
proc ulString*(str: cstring): ULStringStrong {.importc: "ulCreateString".}
  ## Create string from `cstring`.
proc ulString*(str: cstring, len: csize_t): ULStringStrong {.importc: "ulCreateStringUTF8".}
  ## Create string from UTF-8 buffer.
proc ulString*(str: ptr ULChar16, len: csize_t): ULStringStrong {.importc: "ulCreateStringUTF16".}
  ## Create string from UTF-16 buffer.
proc copy*(str: ULString): ULStringStrong {.importc: "ulCreateStringFromCopy".}
  ## Create string from copy of existing string.
  ## This is useful in making your own copy of a weak string returned from a proc  
proc `copy=`*(dest: var ULStringStrong, src: ULString) =
  if dest.pointer != src.pointer:
    `=destroy`(dest)
    wasMoved(dest)
    dest = copy src
proc len*(str: ULString): cint {.importc: "ulStringGetLength".}
  ## Get length in UTF-16 characters.
proc data*(str: ULString): ptr ULChar16 {.importc: "ulStringGetData".}
  ## Get internal UTF-16 buffer data.

proc isEmpty*(str: ULString): bool {.importc: "ulStringIsEmpty".}
  ## Whether this string is empty or not.
# TODO: allow these assigns to be used with `=` operator
proc assign*(str: ULString, newStr: ULString) {.importc: "ulStringAssignString".}
  ## Replaces the contents of **str** with the contents of **new_str**
proc assign*(str: ULString, newStr: cstring) {.importc: "ulStringAssignCString".}
  ## Replaces the contents of **str** with the contents of a `cstring`.
#
# Bitmap
#

proc createEmptyBitmap*(): BitmapStrong {.importc: "ULBitmap".}
  ## Create empty bitmap.
proc createBitmap*(width, height: cuint, format: BitmapFormat): BitmapStrong {.importc: "ulCreateBitmap".}
  ## Create bitmap with certain dimensions and pixel format.
proc createBitmap*(width, height: cuint, format: BitmapFormat, 
                   rowBytes: cuint, pixels: pointer, size: csize_t, shouldCopy: bool): BitmapStrong {.importc: "ulCreateBitmapFromPixels".}
  ## Create bitmap from existing pixel buffer
proc copy*(bitmap: Bitmap): BitmapStrong {.importc: "ulCreateBitmapFromCopy".}
  ## Create bitmap from copy.
proc `copy=`*(dest: var BitmapStrong, src: Bitmap) =
  if dest.pointer != src.pointer:
    `=destroy`(dest)
    wasMoved(dest)
    dest = copy src

proc width*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetWidth".}
  ## Get the width in pixels.
proc height*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetHeight".}
  ## Get the height in pixels.
proc format*(bitmap: Bitmap): BitmapFormat {.importc: "ulBitmapGetFormat".}
  ## Get the pixel format.
proc bpp*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetBpp".}
  ## Get the bytes per pixel.
proc rowBytes*(bitmap: Bitmap): cuint {.importc: "ulBitmapGetRowBytes".}
  ## Get the number of bytes per row.
proc len*(bitmap: Bitmap): csize_t {.importc: "ulBitmapGetSize".}
  ## Get the size in bytes of the underlying pixel buffer.
proc ownsPixels*(bitmap: Bitmap): bool {.importc: "ulBitmapOwnsPixels".}
  ## Whether or not this bitmap owns its own pixel buffer.
proc lockPixels*(bitmap: Bitmap): pointer {.importc: "ulBitmapLockPixels".}
  ## Lock pixels for reading/writing, returns pointer to pixel buffer.
proc unlockPixels*(bitmap: Bitmap) {.importc: "ulBitmapUnlockPixels".}
  ## Unlock pixels after locking.
proc rawPixels*(bitmap: Bitmap) {.importc: "ulBitmapRawPixels".}
  ## Get raw pixel buffer-- you should only call this if Bitmap is already
  ## locked.
proc isEmpty*(bitmap: Bitmap): bool {.importc: "ulBitmapIsEmpty".}
  ## Whether or not this bitmap is empty.
proc erase*(bitmap: Bitmap) {.importc: "ulBitmapErase".}
  ## Reset bitmap pixels to 0.
proc writePNG*(bitmap: Bitmap, path: cstring) {.importc: "ulBitmapWritePNG".}
  ## Write bitmap to a PNG on disk.
proc swapRedBlueChannels*(bitmap: Bitmap) {.importc: "ulBitmapSwapRedBlueChannels".}
  ## This converts a BGRA bitmap to RGBA bitmap and vice-versa by swapping
  ## the red and blue channels.

#
# Mouse/Key/Scroll Events
#

proc createKeyEvent*(kind: KeyEventType, modifiers: cuint, virtualKeyCode, nativeKeyCode: cint,
                     text, unmodifiedText: ULString,
                     isKeypad, isAutoRepeat, isSystemKey: bool) {.importc: "ulCreateKeyEvent".}
  ## Create a key event
proc createMouseEvent*(kind: MouseEventType, x, y: cint, button: MouseButton) {.importc: "ulCreateMouseEvent".}
  ## Create a mouse event
proc createScrollEvent*(kind: ScrollEventType, deltaX, deltaY: cint) {.importc: "ulCreateScrollEvent".}
  ## Create a scroll event
# TODO: Add apis for making key events from native win32/mac key events

#
#  Rect/IntRect
#

proc isEmpty*(rect: Rect): bool {.importc: "ulRectIsEmpty".}
  ## Whether or not a ULRect is empty (all members equal to 0)
proc makeEmptyRect*(): Rect {.importc: "ulRectMakeEmpty".}
  ## Create an empty ULRect (all members equal to 0)

proc isEmpty*(rect: IntRect): bool {.importc: "ulIntRectIsEmpty".}
   ## Whether or not a ULIntRect is empty (all members equal to 0)
proc makeEmptyIntRect*(): IntRect {.importc: "ulIntRectMakeEmpty".}
  ## Create an empty ULIntRect (all members equal to 0)

#
# Surface
#

proc width*(surface: Surface): cuint {.importc: "ulSurfaceGetWidth".} 
  ## Width (in pixels).
proc height*(surface: Surface): cuint {.importc: "ulSurfaceGetHeight".} 
  ## Height (in pixels).
proc rowBytes*(surface: Surface): cuint {.importc: "ulSurfaceGetRowBytes".}
  ## Number of bytes between rows (usually width * 4)
proc len*(surface: Surface): csize_t {.importc: "ulSurfaceGetSize".}
  ## Size in bytes.
proc lockPixels*(surface: Surface): pointer {.importc: "ulSurfaceLockPixels".}
  ## Lock the pixel buffer and get a pointer to the beginning of the data
  ## for reading/writing.
  ##
  ## Native pixel format is premultiplied BGRA 32-bit (8 bits per channel).
proc unlockPixels*(surface: Surface) {.importc: "ulSurfaceUnlockPixels".}
  ## Unlock the pixel buffer.
proc resize*(surface: Surface, width, height: cuint) {.importc: "ulSurfaceResize".}
  ## Resize the pixel buffer to a certain width and height (both in pixels).
  ##
  ## This should never be called while pixels are locked.
proc clearDirtyBounds*(surface: Surface) {.importc: "ulSurfaceClearDirtyBounds".}
  ## Clear the dirty bounds.
  ##
  ## You should call this after you're done displaying the Surface.
proc dirtyBounds*(surface: Surface): IntRect {.importc: "ulSurfaceGetDirtyBounds".}
  ## Get the dirty bounds.
  ##
  ## This value can be used to determine which portion of the pixel buffer has
  ## been updated since the last call to clearDirtyBounds_.
  ##
  ## The general algorithm to determine if a Surface needs display is:
  ##
  ## .. code-block:: nim
  ##
  ##   if surface.dirtyBounds.isEmpty():
  ##     # Surface pixels are dirty and needs display.
  ##     # Cast Surface to native Surface and use it here (pseudo code)
  ##     surface.display()
  ##
  ##     # Once you're done, clear the dirty bounds:
  ##     surface.clearDirtyBounds()
proc userData*(surface: Surface): pointer {.importc: "ulSurfaceGetUserData".}
  ## Get the underlying user data pointer (this is only valid if you have
  ## set a custom surface implementation via ulPlatformSetSurfaceDefinition).
  ##
  ## This will return nullptr if this surface is the default ULBitmapSurface.
proc `dirtyBounds=`*(surface: Surface, bounds: IntRect) {.importc: "ulSurfaceSetDirtyBounds".}
  ## Set the dirty bounds to a certain value.
  ##
  ## This is called after the Renderer paints to an area of the pixel buffer.
  ## (The new value will be joined with the existing dirty_bounds())
proc bitmap*(surface: BitmapSurface) {.importc: "ulBitmapSurfaceGetBitmap".}
  ## Get the underlying Bitmap from the default Surface.

#
# Config
#
  
proc createConfig*(): ConfigStrong {.importc: "ulCreateConfig".}
  ## Create config with default values
proc `resourcePath=`*(config: Config, path: ULString) {.importc: "ulConfigSetResourcePath".}
  ## Set the file path to the directory that contains Ultralight's bundled
  ## resources (eg, cacert.pem and other localized resources).
proc `cachePath=`*(config: Config, path: ULString) {.importc: "ulConfigSetCachePath".}
  ## Set the file path to a writable directory that will be used to store
  ## cookies, cached resources, and other persistent data.
proc `faceWinding=`*(config: Config, winding: FaceWinding) {.importc: "ulConfigSetFaceWinding".}
  ## The winding order for front-facing triangles.
  ##
  ## .. Note:: This is only used with custom GPUDrivers
proc `fontHinting=`*(config: Config, hinting: FontHinting) {.importc: "ulConfigSetFontHinting".}
  ## The hinting algorithm to use when rendering fonts. (Default = `Normal`)
proc `fontGamma=`*(config: Config, gamma: cdouble) {.importc: "ulConfigSetFontGamma".}
  ## The gamma to use when compositing font glyphs, change this value to
  ## adjust contrast (Adobe and Apple prefer 1.8, others may prefer 2.2).
  ## (Default = 1.8)
proc `userCSS=`*(config: Config, css_string: ULString) {.importc: "ulConfigSetUserStylesheet".}
  ## Set user stylesheet (CSS) (Default = Empty).
proc `forceRepaint=`*(config: Config, enabled: bool) {.importc: "ulConfigSetForceRepaint".}
  ## Set whether or not we should continuously repaint any Views or compositor
  ## layers, regardless if they are dirty or not. This is mainly used to
  ## diagnose painting/shader issues. (Default = False)
proc `animationTimerDelay=`*(config: Config, delay: cdouble) {.importc: "ulConfigSetAnimationTimerDelay".}
  ## Set the amount of time to wait before triggering another repaint when a
  ## CSS animation is active. (Default = 1.0 / 60.0)
proc `scrollTimerDelay=`*(config: Config, delay: cdouble) {.importc: "ulConfigSetScrollTimerDelay".}
  ## When a smooth scroll animation is active, the amount of time (in seconds)
  ## to wait before triggering another repaint. Default is 60 Hz.
proc `recycleDelay=`*(config: Config, delay: cdouble) {.importc: "ulConfigSetRecycleDelay".}
  ## The amount of time (in seconds) to wait before running the recycler (will
  ## attempt to return excess memory back to the system). (Default = 4.0)
proc `memoryCacheSize=`*(config: Config, size: cuint) {.importc: "ulConfigSetMemoryCacheSize".}
  ## Set the size of WebCore's memory cache for decoded images, scripts, and
  ## other assets in bytes. (Default = 64 * 1024 * 1024)
proc `pageCacheSize=`*(config: Config, size: cuint) {.importc: "ulConfigSetPageCacheSize".}
  ## Set the number of pages to keep in the cache. (Default = 0)
proc `ramSize=`*(config: Config, size: cuint) {.importc: "ulConfigSetOverrideRAMSize".}
  ## JavaScriptCore tries to detect the system's physical RAM size to set
  ## reasonable allocation limits. Set this to anything other than 0 to
  ## override the detected value. Size is in bytes.
  ##
  ## This can be used to force JavaScriptCore to be more conservative with
  ## its allocation strategy (at the cost of some performance).
proc `minLargeHeapSize=`*(config: Config, size: cuint) {.importc: "ulConfigSetMinLargeHeapSize".}
  ## The minimum size of large VM heaps in JavaScriptCore. Set this to a
  ## lower value to make these heaps start with a smaller initial value.
proc `minSmallHeapSize=`*(config: Config, size: cuint) {.importc: "ulConfigSetMinSmallHeapSize".}
  ## The minimum size of small VM heaps in JavaScriptCore. Set this to a
  ## lower value to make these heaps start with a smaller initial value.
#
# View
#

proc createView*(renderer: Renderer, width, height: cuint, config: ViewConfig, session: Session) {.importc: "ulCreateView".}
  ## Create a View with certain size (in pixels).
  ##
  ## .. Note::  You can pass `nil` to **session** to use the default session.

proc title*(view: View): ULStringWeak {.importc: "ulViewGetTitle".}
proc url*(view: View): ULStringWeak {.importc: "ulViewGetURL".}
  ## Get current URL.
proc width*(view: View): cuint {.importc: "ulViewGetWidth".}
  ## Get the width, in pixels.
proc height*(view: View): cuint {.importc: "ulViewGetHeight".}
  ## Get the height, in pixels.
proc resize*(view: View, width, height: cuint) {.importc: "ulViewResize".}
  ## Resize view to a certain width and height (in pixels).
proc isLoading*(view: View): bool {.importc: "ulViewIsLoading".}
  ## Check if main frame is loading.
proc renderTarget*(view: View): RenderTarget {.importc: "ulViewGetRenderTarget".}
  ## Get the RenderTarget for the View.
  ##
  ## .. Note::  Only valid when the GPU renderer is enabled in Config.
proc surface*(view: View): Surface {.importc: "ulViewGetSurface".}
  ## Get the Surface for the View (native pixel buffer container).
  ##
  ## .. Note:: Only valid when the GPU renderer is disabled in Config.
  ##
  ##        (Will return a nullptr when the GPU renderer is enabled.)
  ##
  ##        The default Surface is BitmapSurface but you can provide your
  ##        own Surface implementation via setPlatformSurfaceDefinition_.
  ##
  ##        When using the default Surface, you can retrieve the underlying
  ##        bitmap by casting `Surface` to `BitmapSurface` and calling
  ##        bitmap_.

proc loadURL*(view: View, url: ULString) {.importc: "ulViewLoadURL".}
  ## Load a URL into main frame.
proc loadHTML*(view: View, html: ULString) {.importc: "ulViewLoadHTML".}
  ## Load a raw string of HTML.

proc lockJSCtx*(view: View): JSContextRef {.importc: "ulViewLockJSContext".}
  ## Acquire the page's JSContext for use with JavaScriptCore API.
  ## 
  ## .. Note::  This call locks the context for the current thread. You should
  ##        call unlockJSCtx_ after using the context so other
  ##        worker threads can modify JavaScript state.
  ##
  ## .. Note::  The lock is recusive, it's okay to call this multiple times as long
  ##        as you call unlockJSCtx_ the same number of times.
proc unlockJSCtx*(view: View) {.importc: "ulViewUnlockJSContext".}
  ## Unlock the page's JSContext after a previous call to lockJSCtx_.
proc evalScript*(view: View, js: ULString, exception: ptr ULStringWeak): ULStringWeak {.importc: "ulViewEvaluateScript".}
  ##
  ## Evaluate a string of JavaScript and return result.
  ##
  ## **js**  The string of JavaScript to evaluate.
  ##
  ## **exception**  The address of a ULString to store a description of the
  ##                    last exception. Pass nil to ignore this. Don't destroy
  ##                    the exception string returned, it's owned by the View.
  ##
  ## An example of using this API:
  ##
  ## .. code-block:: nim
  ##
  ##  let script = ulString"1 + 1"
  ##  var exception: ULStringWeak # Owned by view, not us
  ##  let result = view.evalScript(script, addr exception)
  ##  assert result == ulString"2"
proc canGoBack*(view: View): bool {.importc: "ulViewCanGoBack".}
  ## Check if can navigate backwards in history.
proc canGoForward*(view: View): bool {.importc: "ulViewCanGoForward".}
  ## Check if can navigate forwards in history.
proc goBack*(view: View) {.importc: "ulViewGoBack".}
  ## Navigate backwards in history.
proc goForward*(view: View) {.importc: "ulViewGoForward".}
  ## Navigate forwards in history.
proc gotoHistoryOffset*(view: View, offset: cint) {.importc: "ulViewGoToHistoryOffset".}
  ## Navigate to arbitrary offset in history.
proc reload*(view: View) {.importc: "ulViewReload".}
  ## Reload current page.
proc stop*(view: View) {.importc: "ulViewStop".}
  ## Stop all page loads.
proc focus*(view: View) {.importc: "ulViewFocus".}
  ## Give focus to the View.
  ##
  ## You should call this to give visual indication that the View has input
  ## focus (changes active text selection colors, for example).
proc unfocus*(view: View) {.importc: "ulViewUnfocus".}
  ## Remove focus from the View and unfocus any focused input elements.
  ##
  ## You should call this to give visual indication that the View has lost
  ## input focus.
proc hasFocus*(view: View): bool {.importc: "ulViewHasFocus".}
  ## Whether or not the View has focus.
proc hasInputFocus*(view: View): bool {.importc: "ulViewHasInputFocus".}
  ## Whether or not the View has an input element with visible keyboard focus
  ## (indicated by a blinking caret).
  ##
  ## You can use this to decide whether or not the View should consume
  ## keyboard input events (useful in games with mixed UI and key handling).
proc fireEvent*(view: View, event: KeyEvent) {.importc: "ulViewFireKeyEvent".}
  ## Fire a keyboard event.
proc fireEvent*(view: View, event: MouseEvent) {.importc: "ulViewFireMouseEvent".}
  ## Fire a mouse event.
proc fireEvent*(view: View, event: ScrollEvent) {.importc: "ulViewFireScrollEvent".}
  ## Fire a scroll event.

proc setChangeTitleCallback*(view: View, callback: ChangeTitleCallback, data: pointer) {.importc: "ulViewSetChangeTitleCallback".}
  ## Set callback for when the page title changes.
proc setChangeURLCallback*(view: View, callback: ChangeURLCallback, data: pointer) {.importc: "ulViewSetChangeURLCallback".}
  ## Set callback for when the page URL changes.
proc setChangeTooltipCallback*(view: View, calback: ChangeTooltipCallback, data: pointer) {.importc: "ulViewSetChangeTooltipCallback".}
  ## Set callback for when the tooltip changes (usually result of a mouse hover).
proc setChangeCursorCallback*(view: View, callback: ChangeCursorCallback, data: pointer) {.importc: "ulViewSetChangeCursorCallback".}
  ## Set callback for when the mouse cursor changes.
proc setAddConsoleMessageCallback*(view: View, callback: AddConsoleMessageCallback, data: pointer) {.importc: "ulViewSetAddConsoleMessageCallback".}
  ## Set callback for when a message is added to the console (useful for
  ## JavaScript / network errors and debugging).
proc setCreateChildViewCallback*(view: View, callback: CreateChildViewCallback, data: pointer) {.importc: "ulViewSetCreateChildViewCallback".}
  ## Set callback for when the page wants to create a new View.
  ##
  ## This is usually the result of a user clicking a link with target="_blank"
  ## or by JavaScript calling window.open(url).
  ##
  ## To allow creation of these new Views, you should create a new View in
  ## this callback, resize it to your container,
  ## and return it. You are responsible for displaying the returned View.
  ##
  ## You should return `nil` if you want to block the action.
proc setBeginLoadingCallback*(view: View, callback: BeginLoadingCallback, data: pointer) {.importc: "ulViewSetBeginLoadingCallback".}
  ## Set callback for when the page begins loading a new URL into a frame.
proc setFinishLoadingCallback*(view: View, callback: FinishLoadingCallback, data: pointer) {.importc: "ulViewSetFinishLoadingCallback".}
  ## Set callback for when the page finishes loading a URL into a frame.
proc setFailLoadingCallback*(view: View, callback: FailLoadingCallback, data: pointer) {.importc: "ulViewSetFailLoadingCallback".}
  ## Set callback for when an error occurs while loading a URL into a frame.
proc setWindowObjectReadyCallback*(view: View, callback: WindowObjectReadyCallback, data: pointer) {.importc: "ulViewSetWindowObjectReadyCallback".}
  ## Set callback for when the JavaScript window object is reset for a new
  ## page load.
  ##
  ## This is called before any scripts are executed on the page and is the
  ## earliest time to setup any initial JavaScript state or bindings.
  ##
  ## The document is not guaranteed to be loaded/parsed at this point. If
  ## you need to make any JavaScript calls that are dependent on DOM elements
  ## or scripts on the page, use DOMReady instead.
  ##
  ## The window object is lazily initialized (this will not be called on pages
  ## with no scripts).
proc setDOMReadyCallback*(view: View, callback: DOMReadyCallback, data: pointer) {.importc: "ulViewSetDOMReadyCallback".}
  ## Set callback for when all JavaScript has been parsed and the document is
  ## ready.
  ##
  ## This is the best time to make any JavaScript calls that are dependent on
  ## DOM elements or scripts on the page.
proc setUpdateHistoryCallback*(view: View, callback: UpdateHistoryCallback, data: pointer) {.importc: "ulViewSetUpdateHistoryCallback".}
  ## Set callback for when the history (back/forward state) is modified.

proc `needsPaint=`*(view: View, needsPaint: bool) {.importc: "ulViewSetNeedsPaint".}
  ## Set whether or not a view should be repainted during the next call to
  ## ulRender.
  ##
  ## .. Note::  This flag is automatically set whenever the page content changes
  ##        but you can set it directly in case you need to force a repaint.
proc needsPaint*(view: View): bool {.importc: "ulViewGetNeedsPaint".}
  ## Whether or not a view should be painted during the next call to ulRender.
proc createInspectorView*(view: View): ViewStrong {.importc: "ulViewCreateInspectorView".}
  ## Create an inspector for this View, this is useful for debugging and
  ## inspecting pages locally. This will only succeed if you have the
  ## inspector assets in your filesystem-- the inspector will look for
  ## file:///inspector/Main.html when it loads.
  ##
  ## .. Note::  The initial dimensions of the returned View are 10x10, you should
  ##        call ulViewResize on the returned View to resize it to your desired
  ##        dimensions.
  ##

#
# Renderer
#

proc createRenderer*(config: Config): RendererStrong {.importc: "ulCreateRenderer".}
  ##
  ## Create the Ultralight Renderer directly.
  ##
  ## Unlike `createApp <appcore.html#createApp,Settings,Config>`_, this does not use any native windows for drawing
  ## and allows you to manage your own runloop and painting. This method is
  ## recommended for those wishing to integrate the library into a game.
  ##
  ## This singleton manages the lifetime of all Views and coordinates all
  ## painting, rendering, network requests, and event dispatch.
  ##
  ## You should only call this once per process lifetime.
  ##
  ## You shoud set up your platform handlers (eg, setPlatformLogger_,
  ## setPlatformFilesystem_, etc.) before calling this.
  ##
  ## You will also need to define a font loader before calling this-- 
  ## as of this writing (v1.2) the only way to do this is by calling
  ## `enablePlatformFontLoader <appcore.html#enablePlatformFontLoader>`_.
  ##
  ## .. Note::  You should not call this if you are using `createApp <appcore.html#createApp,Settings,Config>`_, it
  ##         creates its own renderer and provides default implementations for
  ##         various platform handlers automatically.
  ##

proc update*(renderer: Renderer) {.importc: "ulUpdate".}
  ## Update timers and dispatch internal callbacks (JavaScript and network).
proc render*(renderer: Renderer) {.importc: "ulRender".}
  ## Render all active Views.
proc purgeMemory*(renderer: Renderer) {.importc: "ulPurgeMemory".}
  ## Attempt to release as much memory as possible. Don't call this from any
  ## callbacks or driver code.
proc logMemoryUsage*(renderer: Renderer) {.importc: "ulLogMemoryUsage".}
  ## Print detailed memory usage statistics to the log.
  ## (see setPlatformLogger_)
proc defaultSession*(renderer: Renderer): SessionWeak {.importc: "ulDefaultSession".}
  ## Get the default session (persistent session named "default").
#
# Session
#

proc createSession*(renderer: Renderer, persistent: bool, name: ULString) {.importc: "ulCreateSession".}
  ## Create a Session to store local data in (such as cookies, local storage,
  ## application cache, indexed db, etc).
proc isPersistent*(session: Session): bool {.importc: "ulSessionIsPersistent".}
  ## Whether or not is persistent (backed to disk).
proc name*(session: Session): ULStringWeak {.importc: "ulSessionGetName".}
  ## Unique name identifying the session (used for unique disk path).
proc id*(session: Session): culonglong {.importc: "ulSessionGetId".}
  ## Unique numeric Id for the session.
proc diskPath*(session: Session): ULStringWeak {.importc: "ulSessionGetDiskPath".}
  ## The disk path to write to (used by persistent sessions only).
  
#
# File System
#

#
# Platform
#

proc setPlatformLogger*(logger: ULLogger) {.importc: "ulPlatformSetLogger".}

#
# ViewConfig
#

proc createViewConfig*(): ViewConfigStrong {.importc: "ulCreateViewConfig".}
  ## Create view configuration with default values
proc `accelerated=`*(config: ViewConfig, isAccelerated: bool) {.importc: "ulViewConfigSetIsAccelerated".}
  ## When enabled, the View will be rendered to an offscreen GPU texture
  ## using the GPU driver set in ulPlatformSetGPUDriver. You can fetch
  ## details for the texture via ulViewGetRenderTarget.
  ##
  ## When disabled (the default), the View will be rendered to an offscreen
  ## pixel buffer surface. This pixel buffer can optionally be provided by the user--
  ## for more info see surface_.
proc `transparent=`*(config: ViewConfig, isTransparent: bool) {.importc: "ulViewConfigSetIsTransparent".}
proc `initialDeviceScale=`*(config: ViewConfig, initalScale: cdouble) {.importc: "ulViewConfigSetInitialDeviceScale".}
  ## Set the amount that the application DPI has been scaled, used for
  ## scaling device coordinates to pixels and oversampling raster shapes
  ## (Default = 1.0).
proc `initialFocus=`*(config: ViewConfig, isFocused: bool) {.importc: "ulViewConfigSetInitialFocus".}
proc `enableImages=`*(config: ViewConfig, enabled: bool) {.importc: "ulViewConfigSetEnableImages".}
  ## Set whether images should be enabled (Default = True).
proc `enableJS=`*(config: ViewConfig, enabled: bool) {.importc: "ulViewConfigSetEnableImages".}
  ## Set whether JavaScript should be eanbled (Default = True).
proc `fontFamilyStandard=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilyStandard".}
  ## Set default font-family to use (Default = Times New Roman).
proc `fontFamilyFixed=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilyFixed".}
  ## Set default font-family to use for fixed fonts, eg <pre> and <code>
  ## (Default = Courier New).
proc `fontFamilySerif=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilySerif".}
  ## Set default font-family to use for serif fonts (Default = Times New Roman).
proc `fontFamilySansSerif=`*(config: ViewConfig, fontName: ULString) {.importc: "ulViewConfigSetFontFamilySansSerif".}
  ## Set default font-family to use for sans-serif fonts (Default = Arial).
proc `userAgent=`*(config: ViewConfig, agentString: ULString) {.importc: "ulViewConfigSetUserAgent".}
  ## Set user agent string 
{.pop.}

proc `$`*(str: ULString): string =
  ## Converts an UltraLight string into a nim string
  var data = str.data
  result = newString(str.len) 
  for i in 0..<str.len:
    result[i] = chr(data[])
    data += 1

proc echoLog(x: LogLevel, y: ULString) {.cdecl.} = 
  echo x, ": ", y

template withJSCtx*(view: View, ctxIdent, body: untyped) =
  ## Automatically locks the js context, runs body code, then locks context again
  let ctxVar {.inject.} = view.lockJSCtx()
  body
  view.unlockJSCtx()

let echoLogger* = ULLogger(
  log_message: echoLog
) ## Simple logger that just echos to console
