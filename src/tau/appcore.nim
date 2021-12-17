import common  

type 
  WindowFlags* {.size: sizeof(cint).}= enum
    Borderless
    Titled
    Resizable
    Maximizable

  UpdateCallback* = proc (data: pointer)
  CloseCallback*  = proc (data: pointer, window: Window)
  
{.passL: "-lAppCore".}

{.push header: "<AppCore/CAPI.h>", dynlib: DLLAppCore.}

#
# Settings
#


proc createSettings*(): SettingsStrong {.importc: "ulCreateSettings".}
proc `cpuRender=`*(settings: Settings, forceCPU: bool) {.importc: "ulSettingsSetForceCPURenderer".}
proc `developerName=`*(settings: Settings, name: ULString) {.importc: "ulSettingsSetDeveloperName".}
proc `appName=`*(settings: Settings, name: ULString) {.importc: "ulSettingsSetAppName".}
proc `fileSystemPath=`*(settings: Settings, path: ULString) {.importc: "ulSettingsSetFileSystemPath".}
proc `loadShadersFromFS=`*(settinsg: Settings, enabled: bool) {.importc: "ulSettingsSetLoadShadersFromFileSystem".}

#
# App
#

proc createApp*(settings: Settings, config: Config): AppStrong {.importc: "ulCreateApp".}
proc run*(app: App) {.importc: "ulAppRun".}
proc mainMonitor*(app: App): MonitorStrong {.importc: "ulAppGetMainMonitor".}
proc `window=`*(app: App, window: Window) {.importc: "ulAppSetWindow".}
proc setUpdateCallback*(app: App, callback: UpdateCallback, data: pointer) {.importc: "ulAppSetUpdateCallback".}
proc isRunning*(app: App): bool {.importc: "ulAppIsRunning".}
proc renderer*(app: App): RendererWeak {.importc: "ulAppGetRenderer".}
proc quit*(app: App) {.importc: "ulAppQuit".}

#
# Monitor
#
proc scale*(monitor: Monitor): cdouble {.importc: "ulMonitorGetScale".}
proc width*(monitor: Monitor): cuint {.importc: "ulMonitorGetWidth".}
proc height*(monitor: Monitor): cuint {.importc: "ulMonitorGetHeight".}


#
# Window
#

proc createWindow*(monitor: Monitor, width, height: cuint, fullscreen: bool, flags: cuint): WindowStrong {.importc: "ulCreateWindow".}
proc width*(window: Window): cuint  {.importc: "ulWindowGetWidth".}
proc height*(window: Window): cuint {.importc: "ulWindowGetHeight".}
proc screenWidth*(window: Window): cuint {.importc: "ulWindowGetScreenWidth".}
proc screenHeight*(window: Window): cuint {.importc: "ulWindowGetScreenHeight".}
proc setResizeCallback*(window: Window, callback: ResizeCallback, data: pointer) {.importc: "ulWindowSetResizeCallback".}
proc setCloseCallback*(window: Window, callback: CloseCallback, data: pointer) {.importc: "ulWindowSetCloseCallback".}
proc moveTo*(window: Window, x, y: cint) {.importc: "ulWindowMoveTo".}
proc moveToCenter*(window: Window) {.importc: "ulWindowMoveToCenter".}
proc x*(window: Window): cint {.importc: "ulWindowGetPositionX".}
proc y*(window: Window): cint {.importc: "ulWindowGetPositionY".}
proc isFullscreen*(window: Window): bool {.importc: "ulWindowIsFullscreen".}
proc isVisible*(window: Window): bool {.importc: "ulWindowIsVisible".}
proc getScale*(window: Window): cdouble {.importc: "ulWindowGetScale".}
proc show*(window: Window) {.importc: "ulWindowShow".}
proc hide*(window: Window) {.importc: "ulWindowHide".}
proc close*(window: Window) {.importc: "ulWindowClose".}
proc screenToPixels*(window: Window, val: cint) {.importc: "ulWindowScreenToPixels".}
proc pixelsToScreen*(window: Window, val: cint) {.importc: "ulWindowPixelsToScreen".}
proc nativeHandle*(window: Window): pointer {.importc: "ulWindowGetNativeHandle".}

proc `title=`*(window: Window, title: cstring) {.importc: "ulWindowSetTitle".}
proc `cursor=`*(window: Window, cursor: Cursor) {.importc: "ulWindowSetCursor".}

#
# Overlay
#

proc createOverlay*(window: Window, width, height: cuint, x, y: cint): OverlayStrong {.importc: "ulCreateOverlay".}
proc createOverlay*(window: Window, view: View, x, y: cint): OverlayStrong {.importc: "ulCreateOverlayWithView".}
proc view*(overlay: Overlay): ViewStrong {.importc: "ulOverlayGetView".}
proc resize*(overlay: Overlay, width, height: cuint) {.importc: "ulOverlayResize".}
proc width*(overlay: Overlay): cuint {.importc: "ulOverlayGetWidth".}
proc height*(overlay: Overlay): cuint {.importc: "ulOverlayGetHeight".}
proc x*(overlay: Overlay): cuint {.importc: "ulOverlayGetX".}
proc y*(overlay: Overlay): cuint {.importc: "ulOverlayGetY".}
proc moveTo*(overlay: Overlay, x, y: cint) {.importc: "ulOverlayMoveTo".}
proc isHidden*(overlay: Overlay): bool {.importc: "ulOverlayIsHidden".}
proc hide*(overlay: Overlay) {.importc: "ulOverlayHide".}
proc show*(overlay: Overlay) {.importc: "ulOverlayShow".}
proc hasFocus*(overlay: Overlay) {.importc: "ulOverlayHasFocus".}
proc focus*(overlay: Overlay) {.importc: "ulOverlayFocus".}
proc unfocus*(overlay: Overlay) {.importc: "ulOverlayUnfocus".}

#
# Platform
#

proc enablePlatformFontLoader() {.importc: "ulEnablePlatformFontLoader".}
proc enablePlatformFileSystem(baseDir: ULString) {.importc: "ulEnablePlatformFileSystem".}
proc enableDefaultLogger(logPath: ULString) {.importc: "ulEnableDefaultLogger".}

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
