import colorstrip, polaroid
import osproc, strutils, os, hashes
import jsony

type
  Response = object
    art: string
    strip: string
    bottom: string
    title: string
    artist: string
    position: string

let assets = getConfigDir() / "hypr/eww/assets"

let default = Response(art: assets / "default.jpg",
                       strip: assets / "default-strip.jpg",
                       bottom: assets / "default-bottom.jpg",
                       title: "NOTHING",
                       artist: "No One",
                       position: "4:20").toJson()

var track = hash("nothing")

echo default

const opts = {poUsePath, poDaemon, poStdErrToStdOut}
var p = startProcess("playerctl", "", ["metadata", "--format", "\"{{ status }}::{{ mpris:artUrl }}::{{ title }}::{{ artist }}::{{ duration(position) }}\"", "--follow"], nil, opts)

for line in p.lines:
  if line.strip() == "":
    echo default
  else:
    let s = line.split("::")
    
    var
      status = s[0]
      artUrl = s[1].replace("file://", "")
      title = s[2].strip()
      artist = s[3]
      pos = s[4].replace("\"", "")
      h = hash([title, artist])

    if track != h and fileExists(artUrl):
      adjustImageBrightnessContrast(artUrl, assets / "art.png", -10.0, -20.0)
      createColorStripFromFile(assets / "art.png", assets / "strip.png", 800, 30, 6)
      createColorStripFromFile(assets / "art.png", assets / "bottom.png", 330, 5, 1)
      track = h

    echo Response(art: assets / "art.png", strip: assets / "strip.png", bottom: assets / "bottom.png",
                  title: title, artist: artist, position: pos).toJson()
      
