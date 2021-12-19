import common  

type 
  WindowFlags* {.size: sizeof(cint).}= enum
    Borderless
    Titled
    Resizable
    Maximizable
    Hidden

  UpdateCallback* = proc (data: pointer)
  CloseCallback*  = proc (data: pointer, window: Window)
  
{.passL: "-lAppCore".}

{.push header: "<AppCore/CAPI.h>", dynlib: DLLAppCore.}

#
# Settings
#


proc createSettings*(): SettingsStrong {.importc: "ulCreateSettings".}
  ## Create settings with default values
proc `developerName=`*(settings: Settings, name: ULString) {.importc: "ulSettingsSetDeveloperName".}
  ## Set the name of the developer of this app.
  ##
  ## This is used to generate a unique path to store local application data
  ## on the user's machine.
  ##
  ## Default is "MyCompany"
proc `forceCPU=`*(settings: Settings, forceCPU: bool) {.importc: "ulSettingsSetForceCPURenderer".}
  ## Ultralight tries to use the GPU renderer when a compatible GPU is detected.
  ##
  ## Set this to true to force the engine to always use the CPU renderer.
proc `appName=`*(settings: Settings, name: ULString) {.importc: "ulSettingsSetAppName".}
  ## Set the name of this app.
  ##
  ## This is used to generate a unique path to store local application data
  ## on the user's machine.
  ##
  ## Default is "MyApp"
proc `fileSystemPath=`*(settings: Settings, path: ULString) {.importc: "ulSettingsSetFileSystemPath".}
  ## Set the root file path for our file system, you should set this to the
  ## relative path where all of your app data is.
  ##
  ## This will be used to resolve all file URLs, eg file:  ##page.html
  ##
  ## .. Note::  The default path is "./assets/"
  ##        
  ##        This relative path is resolved using the following logic:
  ##         - Windows: relative to the executable path
  ##         - Linux:   relative to the executable path
  ##         - macOS:   relative to YourApp.app/Contents/Resources/
proc `loadShadersFromFS=`*(settinsg: Settings, enabled: bool) {.importc: "ulSettingsSetLoadShadersFromFileSystem".}
  ## Set whether or not we should load and compile shaders from the file system
  ## (eg, from the /shaders/ path, relative to file_system_path).
  ##
  ## If this is false (the default), we will instead load pre-compiled shaders
  ## from memory which speeds up application startup time.
#
# App
#

proc createApp*(settings: Settings, config: Config): AppStrong {.importc: "ulCreateApp".}
  ## Create the App singleton.
  ##
  ## **settings**: Settings to customize App runtime behavior. You can pass `nil` for this parameter to use default settings.
  ##
  ## **config**: Config options for the Ultralight renderer. You can pass `nil` for this parameter to use default config.
  ##
  ## .. Note::  You should only create one of these per application lifetime.
  ##        
  ## .. Note::  Certain Config options may be overridden during App creation,
  ##        most commonly `Config.faceWinding` and `Config.deviceScaleHint`.
proc run*(app: App) {.importc: "ulAppRun".}
  ## Run the main loop.
proc mainMonitor*(app: App): MonitorStrong {.importc: "ulAppGetMainMonitor".}
  ## Get the main monitor (this is never `nil`).
  ##
  ## .. Note::  We'll add monitor enumeration later.
proc setUpdateCallback*(app: App, callback: UpdateCallback, data: pointer) {.importc: "ulAppSetUpdateCallback".}
  ## Set a callback for whenever the App updates. You should update all app
  ## logic here.
  ##
  ## .. Note::  This event is fired right before the run loop calls
  ##        `Renderer.update()` and `Renderer.render()`.
proc isRunning*(app: App): bool {.importc: "ulAppIsRunning".}
  ## Whether or not the App is running.
proc renderer*(app: App): RendererWeak {.importc: "ulAppGetRenderer".}
  ## Get the underlying Renderer instance.
proc quit*(app: App) {.importc: "ulAppQuit".}
  ## Quit the application.
proc `window=`*(app: App, window: Window) {.importc: "ulAppSetWindow".}

#
# Monitor
#
proc scale*(monitor: Monitor): cdouble {.importc: "ulMonitorGetScale".}
  ## Get the monitor's DPI scale (1.0 = 100%).
proc width*(monitor: Monitor): cuint {.importc: "ulMonitorGetWidth".}
  ## Get the width of the monitor (in pixels).
proc height*(monitor: Monitor): cuint {.importc: "ulMonitorGetHeight".}
  ## Get the height of the monitor (in pixels).


#
# Window
#

proc createWindow*(monitor: Monitor, width, height: cuint, fullscreen: bool, flags: cuint): WindowStrong {.importc: "ulCreateWindow".}
  ## Create a new Window.
  ##
  ## **monitor**: The monitor to create the Window on.
  ##
  ## **width**: The width (in screen coordinates).
  ##
  ## **height**: The height (in screen coordinates).
  ##
  ## **fullscreen**: Whether or not the window is fullscreen.
  ##
  ## **flags**  Various window flags
proc width*(window: Window): cuint  {.importc: "ulWindowGetWidth".}
  ## Get window width (in pixels).
proc height*(window: Window): cuint {.importc: "ulWindowGetHeight".}
  ## Get window height (in pixels).
proc screenWidth*(window: Window): cuint {.importc: "ulWindowGetScreenWidth".}
  ## Get window width (in screen coordinates).
proc screenHeight*(window: Window): cuint {.importc: "ulWindowGetScreenHeight".}
  ## Get window height (in screen coordinates).
proc setResizeCallback*(window: Window, callback: ResizeCallback, data: pointer) {.importc: "ulWindowSetResizeCallback".}
  ## Set a callback to be notified when a window resizes
  ## (parameters are passed back in pixels).
  ## This is needed to make the window overlay resize when making an application
  ##
  ## .. code-block:: nim
  ##
  ##   proc onResize(data: pointer, width, height: cuint) {.cdecl.}=
  ##     cast[OverlayWeak](data).resize(width, height)
  ##   window.setResizeCallback(onResize, overlay.pointer)
proc setCloseCallback*(window: Window, callback: CloseCallback, data: pointer) {.importc: "ulWindowSetCloseCallback".}
  ## Set a callback to be notified when a window closes.
proc moveTo*(window: Window, x, y: cint) {.importc: "ulWindowMoveTo".}
  ## Move the window to a new position (in screen coordinates) relative to the top-left of the
  ## monitor area.
proc moveToCenter*(window: Window) {.importc: "ulWindowMoveToCenter".}
  ## Move the window to the center of the monitor.
proc x*(window: Window): cint {.importc: "ulWindowGetPositionX".}
  ## Get the x-position of the window (in screen coordinates) relative to the top-left of the
  ## monitor area.
proc y*(window: Window): cint {.importc: "ulWindowGetPositionY".}
  ## Get the y-position of the window (in screen coordinates) relative to the top-left of the
  ## monitor area.
proc isFullscreen*(window: Window): bool {.importc: "ulWindowIsFullscreen".}
  ## Get whether or not a window is fullscreen.
proc isVisible*(window: Window): bool {.importc: "ulWindowIsVisible".}
  ## Whether or not the window is currently visible (not hidden).
proc scale*(window: Window): cdouble {.importc: "ulWindowGetScale".}
  ## Get the DPI scale of a window.
proc show*(window: Window) {.importc: "ulWindowShow".}
  ## Show the window (if it was previously hidden).
proc hide*(window: Window) {.importc: "ulWindowHide".}
  ## Hide the window.
proc close*(window: Window) {.importc: "ulWindowClose".}
  ## Close a window.
proc screenToPixels*(window: Window, val: cint) {.importc: "ulWindowScreenToPixels".}
  ## Convert screen coordinates to pixels using the current DPI scale.
proc pixelsToScreen*(window: Window, val: cint) {.importc: "ulWindowPixelsToScreen".}
  ## Convert pixels to screen coordinates using the current DPI scale.
proc nativeHandle*(window: Window): pointer {.importc: "ulWindowGetNativeHandle".}
  ## Get the underlying native window handle.
  ##
  ## .. Note:: This is:  
  ##                 - HWND on Windows
  ##                 - NSWindow* on macOS
  ##                 - GLFWwindow* on Linux
proc `title=`*(window: Window, title: cstring) {.importc: "ulWindowSetTitle".}
  ## Set the window title.
proc `cursor=`*(window: Window, cursor: Cursor) {.importc: "ulWindowSetCursor".}
  ## Set the cursor for a window.

#
# Overlay
#

proc createOverlay*(window: Window, width, height: cuint, x, y: cint): OverlayStrong {.importc: "ulCreateOverlay".}
  ## Create a new Overlay.
  ##
  ## **window**  The window to create the Overlay in.
  ##
  ## **width**   The width in pixels.
  ##
  ## **height**  The height in pixels.
  ##
  ## **x**       The x-position (offset from the left of the Window), in
  ##                 pixels.
  ##
  ## **y**       The y-position (offset from the top of the Window), in
  ##                 pixels.
  ##
  ##
  ## .. Note::  Each Overlay is essentially a View and an on-screen quad. You should
  ##        create the Overlay then load content into the underlying View.
proc createOverlay*(window: Window, view: View, x, y: cint): OverlayStrong {.importc: "ulCreateOverlayWithView".}
  ## Create a new Overlay, wrapping an existing View.
  ##
  ## **window**  The window to create the Overlay in. (we currently only
  ##                 support one window per application)
  ##
  ## **view**    The View to wrap (will use its width and height).
  ##
  ## **x**       The x-position (offset from the left of the Window), in
  ##                 pixels.
  ##
  ## **y**       The y-position (offset from the top of the Window), in
  ##                 pixels.
  ##
  ## .. Note::  Each Overlay is essentially a View and an on-screen quad. You should
  ##        create the Overlay then load content into the underlying View
proc view*(overlay: Overlay): ViewWeak {.importc: "ulOverlayGetView".}
  ## Get the underlying View.
proc resize*(overlay: Overlay, width, height: cuint) {.importc: "ulOverlayResize".}
  ## Resize the overlay (and underlying View), dimensions should be
  ## specified in pixels.
proc width*(overlay: Overlay): cuint {.importc: "ulOverlayGetWidth".}
  ## Get the width (in pixels).
proc height*(overlay: Overlay): cuint {.importc: "ulOverlayGetHeight".}
  ## Get the height (in pixels).
proc x*(overlay: Overlay): cuint {.importc: "ulOverlayGetX".}
  ## Get the x-position (offset from the left of the Window), in pixels.
proc y*(overlay: Overlay): cuint {.importc: "ulOverlayGetY".}
  ## Get the y-position (offset from the top of the Window), in pixels.
proc moveTo*(overlay: Overlay, x, y: cint) {.importc: "ulOverlayMoveTo".}
  ## Move the overlay to a new position (in pixels).
proc isHidden*(overlay: Overlay): bool {.importc: "ulOverlayIsHidden".}
  ## Whether or not the overlay is hidden (not drawn).
proc hide*(overlay: Overlay) {.importc: "ulOverlayHide".}
  ## Hide the overlay (will no longer be drawn).
proc show*(overlay: Overlay) {.importc: "ulOverlayShow".}
  ## Show the overlay.
proc hasFocus*(overlay: Overlay) {.importc: "ulOverlayHasFocus".}
  ## Whether or not an overlay has keyboard focus.
proc focus*(overlay: Overlay) {.importc: "ulOverlayFocus".}
  ## Grant this overlay exclusive keyboard focus.
proc unfocus*(overlay: Overlay) {.importc: "ulOverlayUnfocus".}
  ## Remove keyboard focus.

#
# Platform
#

proc enablePlatformFontLoader() {.importc: "ulEnablePlatformFontLoader".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the platform font loader and sets it as the current FontLoader.
proc enablePlatformFileSystem(baseDir: ULString) {.importc: "ulEnablePlatformFileSystem".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the platform file system (needed for loading file:///URLs) and
  ## sets it as the current FileSystem.
  ##
  ## You can specify a base directory path to resolve relative paths against.
proc enableDefaultLogger(logPath: ULString) {.importc: "ulEnableDefaultLogger".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the default logger (writes the log to a file).
  ##
  ## You should specify a writable log path to write the log to 
  ## for example "./ultralight.log".
{.pop.}

#
# Helpers
#

proc createOverlay*(window: Window, x, y: cint = 0): OverlayStrong =
  ## Creates an overlay that is the size of the window at coordinates x and y
  window.createOverlay(window.width, window.height, x, y)

proc createWindow*(monitor: Monitor, width, height: uint, fullscreen: bool, flags: set[WindowFlags]): WindowStrong {.inline.} =
  ## Creates a window that is on a monitor
  monitor.createWindow(width.cuint, height.cuint, fullscreen, cast[cuint](flags))
