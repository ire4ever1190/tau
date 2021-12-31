##
## Tau is high/low level wrapper around `Ultralight <https://ultralig.ht/>`
##
## Most modules have a high and low version which gives you control on how much you want to import (this is done since the high level wrapper uses macros and can slow down compile time, 
## the modules will most likely be merged once IC is merged). Using the high level wrapper is recommended since it automatically manages memory and allows you to use more
## idomatic Nim code

include taulow
include tauhigh
