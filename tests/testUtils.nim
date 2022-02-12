import tau
import std/unittest

test "Finding proc that has overloads":
  proc fun(x: string): int = x.len
  proc fun(x: int): int = x
  
  check:
    findProc(fun, string)("Hello World") == 11
    findProc(fun, int)(9) == 9
    
  check not compiles(findProc(fun, bool))
