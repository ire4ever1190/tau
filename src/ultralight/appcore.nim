import common  

{.passL: "-lAppCore".}

{.push header: "<AppCore/CAPI.h>", dynlib: DllAppCore.}

#
# Settings
#


proc createSettings*(): SettingsStrong {.importc: "ulCreateSettings".}
proc `cpuRender=`*(settings: Settings, useCPU: bool) {.importc: "ulSettingsSetForceCPURenderer".}
proc `appName=`*(settings: SettingsStrong, name: ULString) {.importc: "ulSettingsSetAppName".}

#
# Window
#

proc createWindow*(monitor: Monitor, width, height: cuint, fullscreen: bool, flags: cuint): WindowStrong {.importc: "ulCreateWindow".}

proc `title=`*(window: Window, title: cstring) {.importc: "ulWindowSetTitle".}
proc width*(window: Window): cuint  {.importc: "ulWindowGetWidth".}
proc height*(window: Window): cuint {.importc: "ulWindowGetHeight".}
proc setResizeCallback*(window: Window, callback: ResizeCallback, data: pointer) {.importc: "ulWindowSetResizeCallback".}


#
# Overlay
#

proc createOverlay*(window: Window, width, height: cuint, x, y: cint): OverlayStrong {.importc: "ulCreateOverlay".}
proc getView*(overlay: Overlay): ViewStrong {.importc: "ulOverlayGetView".}
proc resize*(overlay: Overlay, width, height: cuint) {.importc: "ulOverlayResize".}

#
# App
#

proc createApp*(settings: Settings, config: Config): AppStrong {.importc: "ulCreateApp".}
proc run*(app: App) {.importc: "ulAppRun".}
proc mainMonitor*(app: App): MonitorStrong {.importc: "ulAppGetMainMonitor".}
proc `window=`*(app: App, window: Window) {.importc: "ulAppSetWindow".}
proc setDOMReadyCallback*(view: View, callback: DOMReadyCallback, data: pointer) {.importc: "ulViewSetDOMReadyCallback", dynlib: DllAppCore.}

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
