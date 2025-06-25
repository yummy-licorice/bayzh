import os, strutils, jsony

type Output = object
  icon: string
  tooltip: string

let battery = "/sys/class/power_supply/BAT0/"
var output = new Output

let percent = readFile(battery / "capacity")
  .strip()
  .parseInt()

if readFile(battery / "status").strip() == "Charging":
  output.icon = "\uE0BA"
elif percent > 75: output.icon = "\uE0C0"
elif percent > 50: output.icon = "\uE0C2"
elif percent > 25: output.icon = "\uE0C6"
elif percent > 0: output.icon = "\uE0C4"
else: quit 0

output.tooltip = $percent
echo toJson(output)



