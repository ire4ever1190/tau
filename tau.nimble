import strformat


version       = "0.1.0"
author        = "Jake Leahy"
description   = "Bindings to https://ultralig.ht/, lightweight electron alternative"
license       = "MIT"
srcDir        = "src"


# Dependencies

requires "nim >= 1.6.0"
requires "ptr_math >= 0.3.0 & < 0.4.0"

task gendoc, "Generates the documentation":
  rmDir "docs"
  selfExec(fmt"doc --index:on --project --git.url:https://github.com/ire4ever1190/tau --git.commit:{version} --outdir:docs src/tau.nim")
  
