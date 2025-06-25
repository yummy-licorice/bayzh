import std/[os, net, strutils, asyncdispatch, asyncnet, sets, osproc]
import jsony

type
  Hypr = object
    event: AsyncSocket
    cmd: AsyncSocket

  Workspaces = object
    id: int

var
  client: Hypr
  activeWorkspace: int
  workspaces: HashSet[int]
  isInitialized: bool = false

proc getSocketDir(): string =
  ## Get Hyprland IPC socket path from environment
  let signature = getEnv("HYPRLAND_INSTANCE_SIGNATURE")
  let rd = getEnv("XDG_RUNTIME_DIR")
  return rd / "hypr" / signature

proc initHypr(): Future[Hypr] {.async.} =
  ## Initialize the Hyprland sockets client
  let path = getSocketDir()
  result.event = newAsyncSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)
  result.cmd = newAsyncSocket(AF_UNIX, SOCK_STREAM, IPPROTO_IP)
  await result.event.connectUnix(path / ".socket2.sock")
  await result.cmd.connectUnix(path / ".socket.sock")

proc sendCommand(this: Hypr, cmd: string): Future[string] {.async.} =
  ## Send command to Hyprland and get response
  try:
    await this.cmd.send(cmd)
    result = ""
    var buffer = newString(4096)
    
    # Read until we get the complete response
    while true:
      let bytesRead = await this.cmd.recvInto(addr buffer[0], buffer.len)
      if bytesRead <= 0: 
        break
      
      result.add(buffer[0..<bytesRead])
      
      # If we didn't fill the buffer, we likely got everything
      if bytesRead < buffer.len: 
        break
        
    stderr.writeLine("Command '$#' returned: $#" % [cmd, result[0..min(100, result.len-1)]])
    
  except Exception as e:
    stderr.writeLine("Error sending command '$#': $#" % [cmd, e.msg])
    result = ""

proc focusedYuck(ws: int): string =
  ## Generate the yuck code for a focused workspace (big pill)
  "(box :orientation \"h\" :halign \"start\" :valign \"center\" :class \"focused\" (button :onclick \"hyprctl dispatch workspace $#\" \"-----------\"))" % [$ws]

proc unfocusedYuck(ws: int, occupied: bool): string =
  ## Generate the yuck code for an unfocused workspace (small pill)
  let class = if occupied: "occupied" else: "vacant"  
  "(box :orientation \"h\" :halign \"start\" :valign \"center\" :class \"$#\" (button :onclick \"hyprctl dispatch workspace $#\" \"---\"))" % [class, $ws]

proc yuck =
  ## Generate the entire yuck code and output to stdout
  var wss: seq[string]
  stderr.writeLine("Generating yuck with active=$#, workspaces=$#" % [$activeWorkspace, $workspaces])
  
  for i in 1..7:
    if i == activeWorkspace:
      wss.add(focusedYuck(i))
    else:
      if i in workspaces:
        wss.add(unfocusedYuck(i, true))
      else:
        wss.add(unfocusedYuck(i, false))
        
  echo "(box :orientation \"h\" :halign \"start\" :valign \"center\" :space-evenly false :spacing 4 :class \"left\" $#)" % [wss.join(" ")]

proc getWorkspaces(this: Hypr) {.async.} =
  ## Gets the workspaces from hyprctl using persistent connection
  stderr.writeLine("Getting workspaces...")
  workspaces.clear()
  
  let response = execCmdEx("hyprctl -j workspaces").output
  if response.strip() != "":
    try:
      let temp = response.fromJson(seq[Workspaces])
      for ws in temp:
        workspaces.incl(ws.id)
      stderr.writeLine("Found workspaces: $#" % [$workspaces])
    except Exception as e:
      stderr.writeLine("Error parsing workspaces JSON: $#" % [e.msg])
      stderr.writeLine("Raw response: $#" % [response])
  else:
    stderr.writeLine("Empty response from workspaces command")

proc getActiveWorkspace(this: Hypr): Future[int] {.async.} =
  ## Get active workspace using persistent connection
  stderr.writeLine("Getting active workspace...")
  let response = await this.sendCommand("j/activeworkspace")
  if response.strip() != "":
    try:
      let data = response.fromJson(Workspaces)
      stderr.writeLine("Active workspace: $#" % [$data.id])
      return data.id
    except Exception as e:
      stderr.writeLine("Error parsing active workspace JSON: $#" % [e.msg])
      stderr.writeLine("Raw response: $#" % [response])
  else:
    stderr.writeLine("Empty response from active workspace command")
  return 1

proc initializeState(this: Hypr) {.async.} =
  ## Initialize the workspace state
  if not isInitialized:
    stderr.writeLine("Initializing state...")
    activeWorkspace = await this.getActiveWorkspace()
    await this.getWorkspaces()
    yuck()
    isInitialized = true

proc handle(this: Hypr, line: string) {.async.} =
  ## Handle the events when detected
  stderr.writeLine("Handling event: $#" % [line])
  
  if line.startsWith("workspace>>"):
    let parts = line.split(">>")
    if parts.len > 1:
      try:
        activeWorkspace = parts[1].parseInt()
        stderr.writeLine("Workspace changed to: $#" % [$activeWorkspace])
        yuck()
      except Exception as e:
        stderr.writeLine("Error parsing workspace event: $#" % [e.msg])
  
  elif line.startsWith("createworkspace>>") or line.startsWith("destroyworkspace>>"):
    stderr.writeLine("Workspace created/destroyed, refreshing...")
    await this.getWorkspaces()
    yuck()
    
  elif line.startsWith("openwindow>>") or line.startsWith("closewindow>>"):
    # Window events might affect workspace occupancy
    stderr.writeLine("Window opened/closed, refreshing...")
    await this.getWorkspaces()
    yuck()

proc reconnectCmd(this: Hypr) {.async.} =
  ## Reconnect command socket
  try:
    await this.cmd.connectUnix(getSocketDir() / ".socket.sock")
    stderr.writeLine("Command socket reconnected")
  except Exception as e:
    stderr.writeLine("Failed to reconnect command socket: $#" % [e.msg])

proc reconnectEvent(this: Hypr) {.async.} =
  ## Reconnect event socket
  try:
    await this.event.connectUnix(getSocketDir() / ".socket2.sock")
    stderr.writeLine("Event socket reconnected")
  except Exception as e:
    stderr.writeLine("Failed to reconnect event socket: $#" % [e.msg])

proc listen(this: Hypr) {.async.} =
  ## Monitor Hyprland events
  await this.initializeState()
  
  while true:
    try:
      let line = await this.event.recvLine()
      if line == "":
        stderr.writeLine("Event socket disconnected, attempting reconnect...")
        await this.reconnectEvent()
        continue
      await this.handle(line)
    except Exception as e:
      stderr.writeLine("Error in event loop: $#" % [e.msg])
      await this.reconnectEvent()
      await sleepAsync(1000)

proc cleanup(this: Hypr) {.async.} =
  ## Cleanup connections
  try:
    this.cmd.close()
    this.event.close()
  except:
    discard

proc main() {.async.} =
  client = await initHypr()
  
  # Setup cleanup on exit
  addQuitProc(proc() {.noconv.} = 
    waitFor client.cleanup()
  )
  
  await client.listen()

when isMainModule:
  waitFor main()
