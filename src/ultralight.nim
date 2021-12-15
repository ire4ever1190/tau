import ptr_math
const
  DLLAppCore        = "libAppCore.so"
  DLLUltraLightCore = "libUltralightCore.so"
  DLLUltraLight     = "libUltralight.so"
  DLLWebCore        = "libWebCore.so"

template cAPI(module: string): string = module & "/CAPI.h"

type ## Structs
  ULStruct {.final, pure.} = object
  ULPtr = ptr ULStruct
  Config   {.importc: "ULConfig", header: cAPI("Ultralight").} = distinct ULPtr
  Settings {.importc: "ULSettings", header: cAPI("AppCore").} = distinct ULPtr
  App      {.importc: "ULApp", header: cAPI("AppCore").} = distinct ULPtr
  Monitor  {.importc: "ULMonitor", header: cAPI("AppCore").} = distinct ULPtr
  Window   {.importc: "ULWindow", header: cAPI("AppCore").} = distinct ULPtr
  Overlay  {.importc: "ULOverlay", header: cAPI("AppCore").} = distinct ULPtr
  View     {.importc: "ULView", header: cAPI("AppCore").} = distinct ULPtr
  ULString {.importc: "ULString", header: cAPI("Ultralight").} = distinct ULPtr


type ## Callbacks
  ResizeCallback   = proc (data: pointer, width, height: cuint) {.nimcall.}
  DOMReadyCallback = proc (data: pointer, caller: View, frameID: culonglong, isMainFrame: bool, url: ULString) {.nimcall.}

type
  ULChar16 = cushort
  

type ## Enums
  WindowFlags = enum
    Borderless
    Titled
    Resizable
    Maximizable

#
# Config
#

proc destroy(config: Config) {.importc: "ulDestroyConfig", dynlib: DllUltraLight.}
proc `=destroy`(conf: var Config) {.inline.} = 
  destroy conf
  conf = nil
  
proc createConfig(): Config {.importc: "ulCreateConfig", dynlib: DllUltraLight.}

proc destroy(settings: Settings) {.importc: "ulDestroySettings", dynlib: DllAppCore.}
proc `=destroy`(settings: var Settings) {.inline.} = 
  destroy settings
  settings = nil
proc createSettings(): Settings {.importc: "ulCreateSettings", dynlib: DllAppCore.}
proc `cpuRender=`(settings: Settings, useCPU: bool) {.importc: "ulSettingsSetForceCPURenderer", dynlib: DllAppCore.}
proc `appName=`(settings: Settings, name: ULString) {.importc: "ulSettingsSetAppName", dynlib: DllAppCore.}

#
# App
#

proc createApp(settings: Settings, config: Config): App {.importc: "ulCreateApp", dynlib: DllAppCore.}
proc run(app: App) {.importc: "ulAppRun", dynlib: DllAppCore.}
proc mainMonitor(app: App): Monitor {.importc: "ulAppGetMainMonitor", dynlib: DllAppCore.}
proc `window=`(app: App, window: Window) {.importc: "ulAppSetWindow", dynlib: DllAppCore.}

#
# Window
#

proc destroy(window: Window) {.importc: "ulDestroyWindow", dynlib: DllAppCore.}
proc `=destroy`(window: var Window) {.inline.} = 
  destroy window
  window = nil
proc createWindow(monitor: Monitor, width, height: cuint, fullscreen: bool, flags: cuint): Window {.importc: "ulCreateWindow", dynlib: DllAppCore.}
proc createWindow(monitor: Monitor, width, height: uint, fullscreen: bool, flags: set[WindowFlags]): Window {.inline.} =
  monitor.createWindow(width.cuint, height.cuint, fullscreen, cast[cuint](flags))
proc `title=`(window: Window, title: cstring) {.importc: "ulWindowSetTitle", dynlib: DllAppCore.}
proc width(window: Window): cuint  {.importc: "ulWindowGetWidth",  dynlib: DllAppCore.}
proc height(window: Window): cuint {.importc: "ulWindowGetHeight", dynlib: DllAppCore.}
proc setResizeCallback(window: Window, callback: ResizeCallback, data: pointer) {.importc: "ulWindowSetResizeCallback", dynlib: DllAppCore.}

#
# Overlay
#

proc createOverlay(window: Window, width, height: cuint, x, y: cint): Overlay {.importc: "ulCreateOverlay", dynlib: DllAppCore.}
proc destroy(overlay: Overlay) {.importc: "ulDestroyOverlay", dynlib: DllAppCore.}
proc `=destroy`(overlay: var Overlay) {.inline.} = 
  destroy overlay
  overlay = nil
  
proc createOverlay(window: Window, x, y: cint): Overlay =
  window.createOverlay(window.width, window.height, 0, 0)
proc getView(overlay: Overlay): View {.importc: "ulOverlayGetView", dynlib: DllAppCore.}
proc resize(overlay: Overlay, width, height: cuint) {.importc: "ulOverlayResize", dynlib: DllAppCore.}

proc destroy(str: ULString) {.importc: "ulDestroyString", dynlib: DllUltraLight.}
proc `=destroy`(str: var ULString) {.inline.} = 
  destroy str
  str = nil

#
# String
#
  
proc ulString(str: cstring): ULString {.importc: "ulCreateString", dynlib: DllUltraLight.}
proc len(str: ULString): cint {.importc: "ulStringGetLength", dynlib: DLLUltraLight.}
proc data(str: ULString): ptr ULChar16 {.importc: "ulStringGetData", dynlib: DLLUltraLight.}
proc `$`(str: ULString): string =
  ## Converts an UltraLight string into a nim string
  var data = str.data
  result = newStringOfCap(str.len) 
  for i in 0..<str.len:
    result &= chr(data[])
    data += 1
    
proc loadURL(view: View, url: ULString) {.importc: "ulViewLoadURL", dynlib: DLLUltraLight.} 
  
proc setDOMReadyCallback(view: View, callback: DOMReadyCallback, data: pointer) {.importc: "ulViewSetDOMReadyCallback", dynlib: DllAppCore.}

#
# Version info
#

proc versionString(): cstring {.importc: "ulVersionString", dynlib: DllUltraLight.}

when isMainModule:
  # This is made with --gc:arc in mind which is why the destroy functions are never explicitly called
  proc main() =
    let 
      settings = createSettings()
      config = createConfig()
    settings.appName = ulString"TestApp"

    let 
      app = createApp(settings, config)
      window = createWindow(app.mainMonitor, 500, 500, false, {Titled})

      
    window.title = "hello"

    app.window = window

    let 
      overlay = window.createOverlay(0, 0)
      view    = overlay.getView()


    proc onResize(data: pointer, width, height: cuint) =
      cast[Overlay](data).resize(width, height)
    
    proc onDOMReady(data: pointer, caller: View, id: culonglong, mainFrame: bool, url: ULString) = 
      echo "DOM ready"

    window.setResizeCallback(onResize, pointer overlay)
    view.setDOMReadyCallback(onDOMReady, nil)
    view.loadURL ulString"file:///app.html"

    app.run()
  main()
