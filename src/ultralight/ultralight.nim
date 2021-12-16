import common
import ptr_math

{.passL: "-lUltralight".}

{.push dynlib: DllUltraLight, header: "<Ultralight/CAPI.h>".}

#
# Version info
#

proc versionString*(): cstring {.importc: "ulVersionString".}

#
# String
#
  
proc ulString*(str: cstring): ULStringStrong {.importc: "ulCreateString".}
proc len*(str: ULString): cint {.importc: "ulStringGetLength".}
proc data*(str: ULString): ptr ULChar16 {.importc: "ulStringGetData".}

#
# Config
#
  
proc createConfig*(): ConfigStrong {.importc: "ulCreateConfig".}

#
# View
#
proc loadURL*(view: View, url: ULString) {.importc: "ulViewLoadURL".}


proc title*(view: ViewWeak): ULStringWeak {.importc: "ulViewGetTitle".}
proc title*(view: ViewStrong): ULStringWeak {.importc: "ulViewGetTitle".}

{.pop.}

proc `$`*(str: ULString): string =
  ## Converts an UltraLight string into a nim string
  var data = str.data
  result = newStringOfCap(str.len) 
  for i in 0..<str.len:
    result &= chr(data[])
    data += 1
    
