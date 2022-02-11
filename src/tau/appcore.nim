import common {.all.}

type 
  UpdateCallback* = proc (data: pointer) {.nimcall, cdecl.}
  CloseCallback*  = proc (data: pointer, window: WindowRaw) {.nimcall, cdecl.}
  
{.passL: "-lAppCore".}

const
  defaultDynLib = DLLAppCore
  defaultHeader = "<AppCore/CAPI.h>"

setWrapInfo("<AppCore/CAPI.h>", DLLAppCore)



#
# Settings
#


proc ulCreateSettings*(): SettingsStrong {.importc, defC.}
  ## Create settings with default values
  
proc `developerName=`*(settings: SettingsRaw, name: ULStringRaw) {.wrap: "ulSettingsSetDeveloperName".}
  ## Set the name of the developer of this app.
  ##
  ## This is used to generate a unique path to store local application data
  ## on the user's machine.
  ##
  ## Default is "MyCompany"
  
proc `forceCPU=`*(settings: SettingsRaw, forceCPU: bool) {.wrap: "ulSettingsSetForceCPURenderer".}
  ## Ultralight tries to use the GPU renderer when a compatible GPU is detected.
  ##
  ## Set this to true to force the engine to always use the CPU renderer.
proc `appName=`*(settings: SettingsRaw, name: ULStringRaw) {.wrap: "ulSettingsSetAppName".}
  ## Set the name of this app.
  ##
  ## This is used to generate a unique path to store local application data
  ## on the user's machine.
  ##
  ## Default is "MyApp"
proc `fileSystemPath=`*(settings: SettingsRaw, path: ULStringRaw) {.wrap: "ulSettingsSetFileSystemPath".}
  ## Set the root file path for our file system, you should set this to the
  ## relative path where all of your app data is.
  ##
  ## This will be used to resolve all file URLs, eg file:  ///page.html
  ##
  ## .. Note::  The default path is "./assets/"
  ##        
  ##        This relative path is resolved using the following logic:
  ##         - Windows: relative to the executable path
  ##         - Linux:   relative to the executable path
  ##         - macOS:   relative to YourApp.app/Contents/Resources/

proc `loadShadersFromFS=`*(settings: SettingsRaw, enabled: bool) {.wrap: "ulSettingsSetLoadShadersFromFileSystem".}
  ## Set whether or not ultralight should load and compile shaders from the file system
  ## (eg, from the /shaders/ path, relative to file_system_path).
  ##
  ## If this is false (the default), Ultralight will instead load pre-compiled shaders
  ## from memory which speeds up application startup time.

#
# App
#

proc createApp*(settings: SettingsRaw, config: ConfigRaw): AppStrong {.wrap: "ulCreateApp".}
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
  
proc run*(app: AppRaw) {.wrap: "ulAppRun".}
  ## Run the main loop.
  
proc mainMonitor*(app: AppRaw): MonitorStrong {.wrap: "ulAppGetMainMonitor".}
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
  
proc renderer*(app: AppRaw): RendererWeak {.wrap: "ulAppGetRenderer".}
  ## Get the underlying Renderer instance.
  
proc quit*(app: AppRaw) {.wrap: "ulAppQuit".}
  ## Quit the application.
  
proc `window=`*(app: AppRaw, window: WindowRaw) {.wrap: "ulAppSetWindow".}

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

proc createWindow*(monitor: MonitorRaw, width, height: cuint, fullscreen: bool, flags: set[WindowFlag]): WindowStrong {.importc: "ulCreateWindow", defC.}
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
  
proc width*(window: WindowRaw): cuint  {.wrap: "ulWindowGetWidth".}
  ## Get window width (in pixels).
  
proc height*(window: WindowRaw): cuint {.wrap: "ulWindowGetHeight".}
  ## Get window height (in pixels).
  
proc screenWidth*(window: WindowRaw): cuint {.wrap: "ulWindowGetScreenWidth".}
  ## Get window width (in screen coordinates).
  
proc screenHeight*(window: WindowRaw): cuint {.wrap: "ulWindowGetScreenHeight".}
  ## Get window height (in screen coordinates).
  
proc setResizeCallback*(window: WindowRaw, callback: ResizeCallback, data: pointer) {.wrap: "ulWindowSetResizeCallback".}
  ## Set a callback to be notified when a window resizes
  ## (parameters are passed back in pixels).
  ## This is needed to make the window overlay resize when making an application
  ##
  ## .. code-block:: nim
  ##
  ##   proc onResize(data: pointer, width, height: cuint) {.cdecl.}=
  ##     cast[OverlayWeak](data).resize(width, height)
  ##   window.setResizeCallback(onResize, overlay.pointer)
  
proc setCloseCallback*(window: WindowRaw, callback: CloseCallback, data: pointer) {.wrap: "ulWindowSetCloseCallback".}
  ## Set a callback to be notified when a window closes.
  
proc moveTo*(window: WindowRaw, x, y: cint) {.wrap: "ulWindowMoveTo".}
  ## Move the window to a new position (in screen coordinates) relative to the top-left of the
  ## monitor area.
  
proc moveToCenter*(window: WindowRaw) {.wrap: "ulWindowMoveToCenter".}
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
  
proc hide*(window: WindowRaw) {.wrap: "ulWindowHide".}
  ## Hide the window.
  
proc close*(window: WindowRaw) {.wrap: "ulWindowClose".}
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
  
proc `title=`*(window: WindowRaw, title: cstring) {.wrap: "ulWindowSetTitle".}
  ## Set the window title.
  
proc `cursor=`*(window: WindowRaw, cursor: Cursor) {.importc: "ulWindowSetCursor".}
  ## Set the cursor for a window.

#
# Overlay
#

proc createOverlay*(window: WindowRaw, width, height: cuint, x, y: cint): OverlayStrong {.wrap: "ulCreateOverlay".}
  ## Create a new Overlay.
  ##
  ## * **window**  The window to create the Overlay in.
  ##
  ## * **width**   The width in pixels.
  ##
  ## * **height**  The height in pixels.
  ##
  ## * **x**       The x-position (offset from the left of the Window), in pixels.
  ##
  ## * **y**       The y-position (offset from the top of the Window), in pixels.
  ##
  ## .. Note::  Each Overlay is essentially a View and an on-screen quad. You should create the Overlay then load content into the underlying View.
  
proc createOverlay*(window: WindowRaw, view: ViewRaw, x, y: cint): OverlayStrong {.wrap: "ulCreateOverlayWithView".}
  ## Create a new Overlay, wrapping an existing View.
  ##
  ## **window**  The window to create the Overlay in. (Ultralight currently only supports one window per application)
  ##
  ## **view**    The View to wrap (will use its width and height).
  ##
  ## **x**       The x-position (offset from the left of the Window), in pixels.
  ##
  ## **y**       The y-position (offset from the top of the Window), in pixels.
  ##
  ## .. Note::  Each Overlay is essentially a View and an on-screen quad. You should create the Overlay then load content into the underlying View
  
proc view*(overlay: OverlayRaw): ViewWeak {.wrap: "ulOverlayGetView".}
  ## Get the underlying View.
proc resize*(overlay: OverlayRaw, width, height: cuint) {.wrap: "ulOverlayResize".}
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

proc enablePlatformFontLoader*() {.importc: "ulEnablePlatformFontLoader", defC.}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the platform font loader and sets it as the current FontLoader.
  
proc enablePlatformFileSystem*(baseDir: ULStringRaw) {.wrap: "ulEnablePlatformFileSystem".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the platform file system (needed for loading file:///URLs) and
  ## sets it as the current FileSystem.
  ##
  ## You can specify a base directory path to resolve relative paths against.
  
proc enableDefaultLogger*(logPath: ULStringRaw) {.wrap: "ulEnableDefaultLogger".}
  ## This is only needed if you are not calling createApp_.
  ##
  ## Initializes the default logger (writes the log to a file).
  ##
  ## You should specify a writable log path to write the log to 
  ## for example "./ultralight.log".



proc createSettings*(): Settings {.inline.} =
  result = wrap ulCreateSettings()

#
# High level procs
#

proc createOverlay*(window: Window, x, y: int = 0): Overlay =
  ## Creates an overlay that is the size of the window at coordinates x and y
  wrap window.internal.createOverlay(window.width, window.height, cint x, cint y)


proc createWindow*(monitor: Monitor, width, height: uint, fullscreen = false, flags = {Titled}): Window {.inline.} =
  ## Creates a window that is on a monitor
  wrap monitor.internal.createWindow(cuint width, cuint height, fullscreen, flags)

