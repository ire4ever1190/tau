import examplemaker/dsl
import strformat

title("Getting Started", "Making everything ready so you can use τau")

text: """
  In this tutorial, we will be getting `Ultralight <https://ultralig.ht/>`_ installed so that you can start using the library.
"""

template requires(s: string) = discard s

section "Nim":
  text: """
    Just in case you don't have Nim installed, make sure you have at least version 1.6.2 installed (checked via `nim --version`:cmd:).

    If you don't have that installed then install via choosenim with `choosenim 1.6.2`:cmd:

    Now that you have nim installed, you just need to install τau either via `nimble install https://github.com/ire4ever1190/tau`:cmd: or adding to your `.nimble` file
  """
  codeBlock:
    requires "http://github.com/ire4ever1190/tau"


proc makeDlLink(infix: string): string =
  result = "https://ultralight-sdk.sfo2.cdn.digitaloceanspaces.com/ultralight-sdk-latest-" & infix & ".7z"

section "Ultralight":
  text: fmt"""
    Currently, τau is wrapped against the 1.3 beta (v1.2.1 has been tested to work but it'll be missing some functions that are in the documentation) and so you need to install
    the latest builds which are available here

    * `Linux 64bit <{makeDlLink("linux-x64")}>`_
    * `Windows 64bit <{makeDlLink("win-x64")}>`_
    * `Windows 32bit <{makeDlLink("win-x86")}>`_
    * `Mac 64bit <{makeDlLink("mac-x64")}>`_

    When you extract the file you should find these folders

    * **bin**: Contains the dynamic library files
    * **include**: Contains the headers (Nimble installs these so this can be ignored)
    * **license**: License info for the Ultralight
    * **inspector**: Inspector that allows debugging your applications front end (`how to use <https://docs.ultralig.ht/docs/using-the-inspector-view>`_)
    * **samples**: Examples on how to use ultralight (Some are already translated into Nim and posted here)

    The only folder that we are concerned with at the moment is **bin** which needs to be put somewhere that your compiler can find it (or via `--passL:"-L/path/to/bin/folder"`:option:)

    .. Note:: If you get a warning like `warning: libpcre.so.3, needed by /tmp/bin/libglib-2.0.so.0`:literal: then just remove the files other than `libWebCore`, `libUltralight`, `libUltralightCore`, `libAppCore`
    
  """
