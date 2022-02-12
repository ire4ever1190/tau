import os
import tau
## Include this file to get a basic headless app setup

let config* = createConfig()
  
enablePlatformFontLoader()
enablePlatformFileSystem(currentSourcePath.parentDir() / "assets")
enableDefaultLogger("./ultralight.log")

let
  renderer* = createRenderer(config)
  session* = createSession(renderer, false, "testInterop")
  viewConfig* = createViewConfig()
  view* = renderer.createView(500, 500, viewConfig, session)
