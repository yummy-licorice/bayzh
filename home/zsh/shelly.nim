import 
  functions,
  strformat

export
  functions

when isMainModule:
  let
    sep = returnCondition(ok = foreground("△", green), ng = foreground("△", magenta))
    nl = "\n"
    cwd = color(italics(tilde(getCwd())), blue)
    space = " "
    #sep = ">>"
  echo fmt"{nl}{space}{virtualenv()}{cwd}{sep}{space}"
