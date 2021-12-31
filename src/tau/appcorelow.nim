import common  

type 
  WindowFlags* {.size: sizeof(cint).}= enum
    Borderless
    Titled
    Resizable
    Maximizable
    Hidden

  UpdateCallback* = proc (data: pointer)
  CloseCallback*  = proc (data: pointer, window: WindowRaw)
  
{.passL: "-lAppCore".}

{.push header: "<AppCore/CAPI.h>", dynlib: DLLAppCore.}

#
# Settings
#


proc createSettings*(): SettingsStrong {.importc: "ulCreateSettings".}
  ## Create settings with default values
  
proc `developerName=`*(settings: SettingsRaw, name: ULStringRaw) {.importc: "ulSettingsSetDeveloperName".}
  ## Set the name of the developer of this app.
  ##
  ## This is used to generate a unique path to store local application data
  ## on the user's machine.
  ##
  ## Default is "MyCompany"
  
proc `forceCPU=`*(settings: SettingsRaw, forceCPU: bool) {.importc: "ulSettingsSetForceCPURenderer".}
  ## Ultralight tries to use the GPU renderer when a compatible GPU is detected.
  ##
  ## Set this to true to force the engine to always use the CPU renderer.
proc `appName=`*(settings: SettingsRaw, name: ULStringRaw) {.importc: "ulSettingsSetAppName".}
  ## Set the name of this app.
  ##
  ## This is used to generate a unique path to store local application data
  ## on the user's machine.
  ##
  ## Default is "MyApp"
proc `fileSystemPath=`*(settings: SettingsRaw, path: ULStringRaw) {.importc: "ulSettingsSetFileSystemPath".}
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
proc `loadShadersFromFS=`*(settinsg: SettingsRaw, enabled: bool) {.importc: "ulSettingsSetLoadShadersFromFileSystem".}
  ## Set whether or not we should load and compile shaders from the file system
  ## (eg, from the /shaders/ path, relative to file_system_path).
  ##
  ## If this is false (the default), we will instead load pre-compiled shaders
  ## from memory which speeds up application startup time.
#
# App
#

proc createApp*(settings: SettingsRaw, config: ConfigRaw): AppStrong {.importc: "ulCreateApp".}
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
  
proc run*(app: AppRaw) {.importc: "ulAppRun".}
  ## Run the main loop.
  
proc mainMonitor*(app: AppRaw): MonitorStrong {.importc: "ulAppGetMainMonitor".}
  ## Get the main monitor (this is never `nil`).
  ##
  ## .. Note::  We'll add monitor enumeration later.
  
proc setUpdateCallback*(app: AppRaw, callback: UpdateCallback, data: pointer) {.importc: "ulAppSetUpdateCallback".}
  ## Set a callback for whenever the App updates. You should update all app
  ## logic here.
  ##
  ## .. Note::  This event is fired right before the run loop calls
  ##        `Renderer.update()` and `Renderer.render()`.
proc isRunning*(app: AppRaw): bool {.importc: "ulAppIsRunning".}
  ## Whether or not the App is running.
proc renderer*(app: AppRaw): RendererWeak {.importc: "ulAppGetRenderer".}
  ## Get the underlying Renderer instance.
proc quit*(app: AppRaw) {.importc: "ulAppQuit".}
  ## Quit the application.
proc `window=`*(app: AppRaw, window: WindowRaw) {.importc: "ulAppSetWindow".}

#
# Monitor
#
proc scale*(monitor: MonitorRaw): cdouble {.importc: "ulMonitorGetScale".}
  ## Get the monitor's DPI scale (1.0 = 100%).
proc width*(monitor: MonitorRaw): cuint {.importc: "ulMonitorGetWidth".}
  ## Get the width of the monitor (in pixels).
proc height*(monitor: MonitorRaw): cuint {.importc: "ulMonitorGetHeight".}
  ## Get the height of the monitor (in pixels).


#
# Window
#

proc createWindow*(monitor: MonitorRaw, width, height: cuint, fullscreen: bool, flags: cuint): WindowStrong {.importc: "ulCreateWindow".}
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
proc width*(window: WindowRaw): cuint  {.importc: "ulWindowGetWidth".}
  ## Get window width (in pixels).
proc height*(window: WindowRaw): cuint {.importc: "ulWindowGetHeight".}
  ## Get window height (in pixels).
proc screenWidth*(window: WindowRaw): cuint {.importc: "ulWindowGetScreenWidth".}
  ## Get window width (in screen coordinates).
proc screenHeight*(window: WindowRaw): cuint {.importc: "ulWindowGetScreenHeight".}
  ## Get window height (in screen coordinates).
proc setResizeCallback*(window: WindowRaw, callback: ResizeCallback, data: pointer) {.importc: "ulWindowSetResizeCallback".}
proc setResizeCallback*(window: WindowRaw, callback: pointer, data: pointer) {.importc: "ulWindowSetResizeCallback".}
  ## Set a callback to be notified when a window resizes
  ## (parameters are passed back in pixels).
  ## This is needed to make the window overlay resize when making an application
  ##
  ## .. code-block:: nim
  ##
  ##   proc onResize(data: pointer, width, height: cuint) {.cdecl.}=
  ##     cast[OverlayWeak](data).resize(width, height)
  ##   window.setResizeCallback(onResize, overlay.pointer)
proc setCloseCallback*(window: WindowRaw, callback: CloseCallback, data: pointer) {.importc: "ulWindowSetCloseCallback".}
  ## Set a callback to be notified when a window closes.
proc moveTo*(window: WindowRaw, x, y: cint) {.importc: "ulWindowMoveTo".}
  ## Move the window to a new position (in screen coordinates) relative to the top-left of the
  ## monitor area.
proc moveToCenter*(window: WindowRaw) {.importc: "ulWindowMoveToCenter".}
  ## Move the window to the center of the monitor.
proc x*(window: WindowRaw): cint {.importc: "ulWindowGetPositionX".}
  ## Get the x-position of the window (in screen coordinates) relative to the top-left of the
  ## monitor area.
proc y*(window: WindowRaw): cint {.importc: "ulWindowGetPositionY".}
  ## Get the y-position of the window (in screen coordinates) relative to the top-left of the
  ## monitor area.
proc isFullscreen*(window: WindowRaw): bool {.importc: "ulWindowIsFullscreen".}
  ## Get whether or not a window is fullscreen.
proc isVisible*(window: WindowRaw): bool {.importc: "ulWindowIsVisible".}
  ## Whether or not the window is currently visible (not hidden).
proc scale*(window: WindowRaw): cdouble {.importc: "ulWindowGetScale".}
  ## Get the DPI scale of a window.
proc show*(window: WindowRaw) {.importc: "ulWindowShow".}
  ## Show the window (if it was previously hidden).
proc hide*(window: WindowRaw) {.importc: "ulWindowHide".}
  ## Hide the window.
proc close*(window: WindowRaw) {.importc: "ulWindowClose".}
  ## Close a window.
proc screenToPixels*(window: WindowRaw, val: cint) {.importc: "ulWindowScreenToPixels".}
  ## Convert screen coordinates to pixels using the current DPI scale.
proc pixelsToScreen*(window: WindowRaw, val: cint) {.importc: "ulWindowPixelsToScreen".}
  ## Convert pixels to screen coordinates using the current DPI scale.
proc nativeHandle*(window: WindowRaw): pointer {.importc: "ulWindowGetNativeHandle".}
  ## Get the underlying native window handle.
  ##
  ## .. Note:: This is:  
  ##                 - HWND on Windows
  ##                 - NSWindow* on macOS
  ##                 - GLFWwindow* on Linux
proc `title=`*(window: WindowRaw, title: cstring) {.importc: "ulWindowSetTitle".}
  ## Set the window title.
proc `cursor=`*(window: WindowRaw, cursor: Cursor) {.importc: "ulWindowSetCursor".}
  ## Set the cursor for a window.

#
# Overlay
#

proc createOverlay*(window: WindowRaw, width, height: cuint, x, y: cint): OverlayStrong {.importc: "ulCreateOverlay".}
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
  
proc createOverlay*(window: WindowRaw, view: View, x, y: cint): OverlayStrong {.importc: "ulCreateOverlayWithView".}
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
  
proc view*(overlay: OverlayRaw): ViewWeak {.importc: "ulOverlayGetView".}
  ## Get the underlying View.
proc resize*(overlay: OverlayRaw, width, height: cuint) {.importc: "ulOverlayResize".}
  ## Resize the overlay (and underlying View), dimensions should be
  ## specified in pixels.
proc width*(overlay: OverlayRaw): cuint {.importc: "ulOverlayGetWidth".}
  ## Get the width (in pixels).
proc height*(overlay: OverlayRaw): cuint {.importc: "ulOverlayGetHeight".}
  ## Get the height (in pixels).
proc x*(overlay: OverlayRaw): cuint {.importc: "ulOverlayGetX".}
  ## Get the x-position (offset from the left of the Window), in pixels.
proc y*(overlay: OverlayRaw): cuint {.importc: "ulOverlayGetY".}
  ## Get the y-position (offset from the top of the Window), in pixels.
proc moveTo*(overlay: OverlayRaw, x, y: cint) {.importc: "ulOverlayMoveTo".}
  ## Move the overlay to a new position (in pixels).
proc isHidden*(overlay: OverlayRaw): bool {.importc: "ulOverlayIsHidden".}
  ## Whether or not the overlay is hidden (not drawn).
proc hide*(overlay: OverlayRaw) {.importc: "ulOverlayHide".}
  ## Hide the overlay (will no longer be drawn).
proc show*(overlay: OverlayRaw) {.importc: "ulOverlayShow".}
  ## Show the overlay.
proc hasFocus*(overlay: OverlayRaw) {.importc: "ulOverlayHasFocus".}
  ## Whether or not an overlay has keyboard focus.
proc focus*(overlay: OverlayRaw) {.importc: "ulOverlayFocus".}
  ## Grant this overlay exclusive keyboard focus.
proc unfocus*(overlay: OverlayRaw) {.importc: "ulOverlayUnfocus".}
  ## Remove keyboard focus.

#
# Platform
#

proc enablePlatformFontLoader() {.importc: "ulEnablePlatformFontLoader".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the platform font loader and sets it as the current FontLoader.
proc enablePlatformFileSystem(baseDir: ULStringRaw) {.importc: "ulEnablePlatformFileSystem".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the platform file system (needed for loading file:///URLs) and
  ## sets it as the current FileSystem.
  ##
  ## You can specify a base directory path to resolve relative paths against.
proc enableDefaultLogger(logPath: ULStringRaw) {.importc: "ulEnableDefaultLogger".}
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

