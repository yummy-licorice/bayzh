{.pragma: vipsLib, dynlib: "libvips.so.42".}
{.passC: gorge("pkg-config --cflags vips").}
{.passL: gorge("pkg-config --libs vips").}

import strutils, sequtils, algorithm, math, os, tables, random

type
  gint* = cint
  gsize* = csize_t
  gpointer* = pointer
  gboolean* = cint
  gdouble* = cdouble
  gchar* = cchar

type
  GObject* = object of RootObj
  VipsObject* = object of GObject
  VipsImage* {.importc: "VipsImage", header: "vips/vips.h".} = object of VipsObject

type
  VipsFormat* = cint
  Format* {.importc: "VipsFormat", header: "vips/vips.h", size: sizeof(cint).} = enum
    VIPS_FORMAT_UCHAR = 0.cint
    VIPS_FORMAT_FLOAT = 6.cint

type VipsInterpretation* {.
  importc: "VipsInterpretation", header: "vips/vips.h", size: sizeof(cint)
.} = enum
  VIPS_INTERPRETATION_MULTIBAND = 0
  VIPS_INTERPRETATION_B_W = 1
  VIPS_INTERPRETATION_RGB = 17
  VIPS_INTERPRETATION_sRGB = 22

type VipsError* = object of CatchableError
type ColorKey = uint32
type Color = object
  r, g, b: uint8
  frequency: int

proc vips_init*(argv0: cstring): cint {.importc: "vips_init", header: "vips/vips.h".}

proc g_object_ref*(obj: pointer): pointer {.importc: "g_object_ref", header: "glib-object.h".}
proc g_object_unref*(obj: pointer) {.importc: "g_object_unref", header: "glib-object.h".}

proc vips_image_new_from_file*(
  filename: cstring, args: pointer
): ptr VipsImage {.importc: "vips_image_new_from_file", header: "vips/vips.h".}

proc vips_image_get_width*(image: ptr VipsImage): cint {.importc: "vips_image_get_width", header: "vips/vips.h".}
proc vips_image_get_height*(image: ptr VipsImage): cint {.importc: "vips_image_get_height", header: "vips/vips.h".}
proc vips_image_get_bands*(image: ptr VipsImage): cint {.importc: "vips_image_get_bands", header: "vips/vips.h".}
proc vips_image_get_interpretation*(image: ptr VipsImage): VipsInterpretation {.importc: "vips_image_get_interpretation", header: "vips/vips.h".}

proc vips_image_write_to_file*(
  image: ptr VipsImage, filename: cstring, args: pointer
): cint {.importc: "vips_image_write_to_file", header: "vips/vips.h".}

proc vips_image_write_to_memory*(
  image: ptr VipsImage, size: ptr csize_t
): pointer {.importc: "vips_image_write_to_memory", header: "vips/vips.h".}

proc vips_resize*(
  input: ptr VipsImage, output: ptr ptr VipsImage, scale: cdouble, args: pointer
): cint {.importc: "vips_resize", header: "vips/vips.h".}

proc vips_colourspace*(
  input: ptr VipsImage, output: ptr ptr VipsImage, space: VipsInterpretation, args: pointer
): cint {.importc: "vips_colourspace", header: "vips/vips.h".}

proc vips_join*(
  left: ptr VipsImage, right: ptr VipsImage, output: ptr ptr VipsImage, direction: cint, args: pointer
): cint {.importc: "vips_join", header: "vips/vips.h".}

proc vips_black*(
  output: ptr ptr VipsImage, width: cint, height: cint, args: pointer
): cint {.importc: "vips_black", header: "vips/vips.h".}

proc vips_linear*(
  input: ptr VipsImage, output: ptr ptr VipsImage, a: ptr cdouble, b: ptr cdouble, n: cint, args: pointer
): cint {.importc: "vips_linear", header: "vips/vips.h".}

proc vips_error_buffer*(): cstring {.importc: "vips_error_buffer", header: "vips/vips.h".}
proc vips_error_clear*() {.importc: "vips_error_clear", header: "vips/vips.h".}

proc checkVipsResult*(result: cint, operation: string = "vips operation") {.inline.} =
  if result != 0:
    let errorMsg = $vips_error_buffer()
    vips_error_clear()
    raise newException(VipsError, operation & " failed: " & errorMsg)

proc quantizeColor(r, g, b: uint8): ColorKey {.inline.} =
  let qr = (r shr 3) shl 3
  let qg = (g shr 3) shl 3
  let qb = (b shr 3) shl 3
  return (qr.uint32 shl 16) or (qg.uint32 shl 8) or qb.uint32

proc colorDistance(c1, c2: Color): float =
  let dr = c1.r.float - c2.r.float
  let dg = c1.g.float - c2.g.float
  let db = c1.b.float - c2.b.float
  return sqrt(dr * dr + dg * dg + db * db)

proc isSimilar(c1, c2: Color, threshold: float = 40.0): bool =
  return colorDistance(c1, c2) < threshold

proc getSaturation(color: Color): float =
  let r = color.r.float / 255.0
  let g = color.g.float / 255.0
  let b = color.b.float / 255.0
  let maxVal = max(max(r, g), b)
  let minVal = min(min(r, g), b)
  if maxVal == 0.0:
    return 0.0
  return (maxVal - minVal) / maxVal

proc getHue(color: Color): float =
  let r = color.r.float / 255.0
  let g = color.g.float / 255.0
  let b = color.b.float / 255.0
  let maxVal = max(max(r, g), b)
  let minVal = min(min(r, g), b)
  let delta = maxVal - minVal
  
  if delta == 0.0:
    return 0.0
  
  var hue: float
  if maxVal == r:
    hue = ((g - b) / delta) mod 6.0
  elif maxVal == g:
    hue = (b - r) / delta + 2.0
  else:
    hue = (r - g) / delta + 4.0
  
  return hue * 60.0

proc getBrightness(color: Color): float =
  let r = color.r.float / 255.0
  let g = color.g.float / 255.0
  let b = color.b.float / 255.0
  return max(max(r, g), b)

proc selectDistinctColors(colors: seq[Color], numColors: int): seq[Color] =
  if colors.len == 0:
    return @[]
  
  var candidates = colors.filterIt(getSaturation(it) < 0.7)
  if candidates.len < numColors:
    candidates = colors
  
  candidates.sort(proc(a, b: Color): int =
    let satA = getSaturation(a)
    let satB = getSaturation(b)
    let freqA = a.frequency.float
    let freqB = b.frequency.float
    let scoreA = (1.0 - satA) * 0.6 + (freqA / 1000.0) * 0.4
    let scoreB = (1.0 - satB) * 0.6 + (freqB / 1000.0) * 0.4
    return cmp(scoreB, scoreA)
  )
  
  var selected = newSeq[Color]()
  var i = 0
  
  while selected.len < numColors and i < candidates.len:
    let candidate = candidates[i]
    let saturation = getSaturation(candidate)
    let brightness = getBrightness(candidate)
    
    let washedOutScore = (1.0 - saturation) + (brightness * 0.5)
    let randomBoost = rand(0.3)
    
    if washedOutScore + randomBoost > 0.8:
      var isTooSimilar = false
      for existing in selected:
        if isSimilar(candidate, existing):
          isTooSimilar = true
          break
      
      if not isTooSimilar:
        selected.add(candidate)
    
    i += 1
  
  while selected.len < numColors and candidates.len > selected.len:
    for candidate in candidates:
      if selected.len >= numColors:
        break
      
      var alreadySelected = false
      for existing in selected:
        if candidate.r == existing.r and candidate.g == existing.g and candidate.b == existing.b:
          alreadySelected = true
          break
      
      if not alreadySelected:
        var isTooSimilar = false
        for existing in selected:
          if isSimilar(candidate, existing, 25.0):
            isTooSimilar = true
            break
        
        if not isTooSimilar:
          selected.add(candidate)
  
  selected.sort(proc(a, b: Color): int =
    let hueA = getHue(a)
    let hueB = getHue(b)
    let brightA = getBrightness(a)
    let brightB = getBrightness(b)
    let hueCompare = cmp(hueA, hueB)
    if hueCompare != 0:
      return hueCompare
    return cmp(brightB, brightA)
  )
  
  return selected

proc extractDominantColors*(image: ptr VipsImage, numColors: int = 8): seq[Color] =
  var resized: ptr VipsImage
  let width = vips_image_get_width(image)
  let height = vips_image_get_height(image)
  
  let maxDim = max(width, height)
  if maxDim > 64:
    let scale = 64.0 / maxDim.float
    checkVipsResult(vips_resize(image, resized.addr, scale, nil))
  else:
    resized = image
    discard g_object_ref(resized)
  
  var rgbImage: ptr VipsImage
  let interpretation = vips_image_get_interpretation(resized)
  if interpretation != VIPS_INTERPRETATION_sRGB and interpretation != VIPS_INTERPRETATION_RGB:
    checkVipsResult(vips_colourspace(resized, rgbImage.addr, VIPS_INTERPRETATION_sRGB, nil))
    g_object_unref(resized)
  else:
    rgbImage = resized
  
  let w = vips_image_get_width(rgbImage).int
  let h = vips_image_get_height(rgbImage).int
  let bands = vips_image_get_bands(rgbImage).int
  
  var size: csize_t
  let data = vips_image_write_to_memory(rgbImage, size.addr)
  g_object_unref(rgbImage)
  
  if data == nil:
    raise newException(VipsError, "Failed to get image data")
  
  let pixels = cast[ptr UncheckedArray[uint8]](data)
  var colorMap = initTable[ColorKey, Color](512)
  
  let stride = w * bands
  let step = max(1, min(w, h) div 16)
  
  for y in countup(0, h-1, step):
    let rowStart = y * stride
    for x in countup(0, w-1, step):
      let idx = rowStart + x * bands
      if idx + 2 < size.int:
        let r = pixels[idx]
        let g = pixels[idx + 1]  
        let b = pixels[idx + 2]
        let key = quantizeColor(r, g, b)
        
        if key in colorMap:
          colorMap[key].frequency += 1
        else:
          colorMap[key] = Color(r: r, g: g, b: b, frequency: 1)
  
  var colors = newSeqOfCap[Color](colorMap.len)
  for color in colorMap.values:
    colors.add(color)
  
  colors.sort(proc(a, b: Color): int = cmp(b.frequency, a.frequency))
  
  return selectDistinctColors(colors, numColors)

proc createColorStrip*(image: ptr VipsImage, stripWidth: int = 400, stripHeight: int = 60, numColors: int = 8): ptr VipsImage =
  let colors = extractDominantColors(image, numColors)
  if colors.len == 0:
    raise newException(VipsError, "No colors extracted from image")
  
  let colorWidth = stripWidth div colors.len
  var strips = newSeqOfCap[ptr VipsImage](colors.len)
  
  for color in colors:
    var blackStrip: ptr VipsImage
    checkVipsResult(vips_black(blackStrip.addr, colorWidth.cint, stripHeight.cint, nil))
    
    var rgbStrip: ptr VipsImage
    checkVipsResult(vips_colourspace(blackStrip, rgbStrip.addr, VIPS_INTERPRETATION_sRGB, nil))
    g_object_unref(blackStrip)
    
    var a = [0.0, 0.0, 0.0]
    var b = [color.r.float, color.g.float, color.b.float]
    
    var coloredStrip: ptr VipsImage
    checkVipsResult(vips_linear(rgbStrip, coloredStrip.addr, a[0].addr, b[0].addr, 3, nil))
    g_object_unref(rgbStrip)
    
    strips.add(coloredStrip)
  
  if strips.len == 1:
    return strips[0]
  
  result = strips[0]
  for i in 1..<strips.len:
    var joined: ptr VipsImage
    checkVipsResult(vips_join(result, strips[i], joined.addr, 0, nil))
    if i > 1:
      g_object_unref(result)
    result = joined
    g_object_unref(strips[i])

proc createColorStripFromFile*(inputPath: string, outputPath: string, stripWidth: int = 400, stripHeight: int = 60, numColors: int = 8) =
  randomize()
  
  if vips_init("color_strip".cstring) != 0:
    raise newException(VipsError, "Failed to initialize VIPS")
    
  try:
    let image = vips_image_new_from_file(inputPath.cstring, nil)
    if image == nil:
      raise newException(VipsError, "Failed to load image: " & inputPath)
    defer: g_object_unref(image)
    
    let strip = createColorStrip(image, stripWidth, stripHeight, numColors)
    defer: g_object_unref(strip)
    
    checkVipsResult(vips_image_write_to_file(strip, outputPath.cstring, nil))
    
    #echo "Color strip created successfully: ", outputPath
    #echo "Extracted ", numColors, " dominant colors from ", inputPath
    
  except VipsError as e:
    echo "Error: ", e.msg
    let errorMsg = $vips_error_buffer()
    if errorMsg.len > 0:
      echo "VIPS error: ", errorMsg
      vips_error_clear()
  except Exception as e:
    echo "Unexpected error: ", e.msg

when isMainModule:
  if paramCount() < 2:
    echo "Usage: ", paramStr(0), " <input_image> <output_image> [width] [height] [num_colors]"
    echo "Example: ", paramStr(0), " input.jpg output.jpg 600 80 10"
    quit(1)
  
  let inputPath = paramStr(1)
  let outputPath = paramStr(2)
  let width = if paramCount() >= 3: parseInt(paramStr(3)) else: 800
  let height = if paramCount() >= 4: parseInt(paramStr(4)) else: 30
  let numColors = if paramCount() >= 5: parseInt(paramStr(5)) else: 6
  
  createColorStripFromFile(inputPath, outputPath, width, height, numColors)
