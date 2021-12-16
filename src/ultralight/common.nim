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

# How does this work without headers?

type ## Structs
  ULStruct* {.final, pure.} = object
  ULPtr* = ptr ULStruct

macro importType(kind: untyped, name: static[string] = "") = 
  ## Creates three type definitions
  ##  - Strong: Pointer which can be destroyed
  ##  - Weak: Pointer which cannot be destroyed (usually it is handled by something else)
  ##  - Both: A generic type for both
  ## Strong and Weak have respective prefixes (e.g. AppStrong, AppWeak) while Both has none (e.g. App)
  ## Using the both is fine for most cases for a parameter but the Weak and Strong types should be carefully choosen for each return type of
  ## a proc imported
  echo name
  let 
    typeIdent = ident(if name == "":  replace($kind, "UL", "") else: name)
    strongIdent = ident $typeIdent & "Strong"
    weakIdent = ident $typeIdent & "Weak"
    cAPIName  = newStrLitNode $kind
  result = quote do:
    type
      `strongIdent`* {.importc: `cAPIName`.} = distinct ULPtr
      `weakIdent`* {.importc: `cAPIName`.} = distinct ptr ULStruct
      `typeIdent`* = `strongIdent` | `weakIdent`

importType ULConfig
importType ULSettings
importType ULApp
importType ULMonitor
importType ULWindow
importType ULOverlay
importType ULView
importType(ULString, "ULString")

type ## Callbacks
  ResizeCallback*   = proc (data: pointer, width, height: cuint) {.nimcall, cdecl.}
  DOMReadyCallback* = proc (data: pointer, caller: ViewStrong, frameID: culonglong, isMainFrame: bool, url: ULStringWeak) {.nimcall, cdecl.}

type ## Aliases
  ULChar16* = cushort
  

type ## Enums
  WindowFlags* = enum
    Borderless
    Titled
    Resizable
    Maximizable

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
    proc `destructorName`*(`loweredName`: var `kind`) =
      if `loweredName`.pointer != nil:
        destroy `loweredName`
        `loweredName` = nil    

importDestructor(SettingsStrong, DllAppCore)
importDestructor(ConfigStrong, DllUltralight)
importDestructor(WindowStrong, DllAppCore)
importDestructor(OverlayStrong, DllAppCore)
importDestructor(ULStringStrong, DllUltraLight)
