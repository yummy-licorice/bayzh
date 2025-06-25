{.pragma: vipsLib, dynlib: "libvips.so.42".}
{.passC: gorge("pkg-config --cflags vips").}
{.passL: gorge("pkg-config --libs vips").}

import strutils, os

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

type VipsError* = object of CatchableError

proc vips_init*(argv0: cstring): cint {.importc: "vips_init", header: "vips/vips.h".}

proc g_object_ref*(obj: pointer): pointer {.importc: "g_object_ref", header: "glib-object.h".}
proc g_object_unref*(obj: pointer) {.importc: "g_object_unref", header: "glib-object.h".}

proc vips_image_new_from_file*(
  filename: cstring, args: pointer
): ptr VipsImage {.importc: "vips_image_new_from_file", header: "vips/vips.h".}

proc vips_image_write_to_file*(
  image: ptr VipsImage, filename: cstring, args: pointer
): cint {.importc: "vips_image_write_to_file", header: "vips/vips.h".}

proc vips_linear*(
  input: ptr VipsImage, output: ptr ptr VipsImage, a: ptr cdouble, b: ptr cdouble, n: cint, args: pointer
): cint {.importc: "vips_linear", header: "vips/vips.h".}

proc vips_crop*(
  input: ptr VipsImage, output: ptr ptr VipsImage, left: cint, top: cint, width: cint, height: cint, args: pointer
): cint {.importc: "vips_crop", header: "vips/vips.h".}

proc vips_image_get_bands*(image: ptr VipsImage): cint {.importc: "vips_image_get_bands", header: "vips/vips.h".}
proc vips_image_get_width*(image: ptr VipsImage): cint {.importc: "vips_image_get_width", header: "vips/vips.h".}
proc vips_image_get_height*(image: ptr VipsImage): cint {.importc: "vips_image_get_height", header: "vips/vips.h".}

proc vips_error_buffer*(): cstring {.importc: "vips_error_buffer", header: "vips/vips.h".}
proc vips_error_clear*() {.importc: "vips_error_clear", header: "vips/vips.h".}

proc checkVipsResult*(result: cint, operation: string = "vips operation") {.inline.} =
  if result != 0:
    let errorMsg = $vips_error_buffer()
    vips_error_clear()
    raise newException(VipsError, operation & " failed: " & errorMsg)

proc makeSquare*(image: ptr VipsImage): ptr VipsImage =
  let width = vips_image_get_width(image).int
  let height = vips_image_get_height(image).int
  
  if width == height:
    return cast[ptr VipsImage](g_object_ref(image))
  
  let squareSize = min(width, height)
  
  let left = (width - squareSize) div 2
  let top = (height - squareSize) div 2
  
  var output: ptr VipsImage
  checkVipsResult(
    vips_crop(image, output.addr, left.cint, top.cint, squareSize.cint, squareSize.cint, nil),
    "crop to square"
  )
  
  return output

proc adjustBrightnessContrast*(image: ptr VipsImage, brightnessPercent: float, contrastPercent: float): ptr VipsImage =
  let bands = vips_image_get_bands(image).int
  
  let contrastMultiplier = 1.0 + (contrastPercent / 100.0)
  let brightnessOffset = (brightnessPercent / 100.0) * 255.0
  
  var a = newSeq[cdouble](bands)
  var b = newSeq[cdouble](bands)
  
  for i in 0..<bands:
    a[i] = contrastMultiplier
    b[i] = brightnessOffset
  
  var output: ptr VipsImage
  checkVipsResult(vips_linear(image, output.addr, a[0].addr, b[0].addr, bands.cint, nil), "adjust brightness/contrast")
  
  return output

proc adjustImageBrightnessContrast*(inputPath: string, outputPath: string, brightnessReduction: float = -10.0, contrastReduction: float = -20.0) =
  if vips_init("brightness_contrast".cstring) != 0:
    raise newException(VipsError, "Failed to initialize VIPS")
  
  try:
    let image = vips_image_new_from_file(inputPath.cstring, nil)
    if image == nil:
      raise newException(VipsError, "Failed to load image: " & inputPath)
    defer: g_object_unref(image)
    
    let squared = makeSquare(image)
    defer: g_object_unref(squared)
    
    let adjusted = adjustBrightnessContrast(squared, brightnessReduction, contrastReduction)
    defer: g_object_unref(adjusted)
    
    checkVipsResult(vips_image_write_to_file(adjusted, outputPath.cstring, nil), "save processed image")

    #echo outputPath
    #echo "Image processed successfully: ", outputPath
    #echo "Original size: ", originalWidth, "x", originalHeight
    #echo "Final size: ", min(originalWidth, originalHeight), "x", min(originalWidth, originalHeight), " (square)"
    #echo "Brightness reduced by ", abs(brightnessReduction), "%"
    #echo "Contrast reduced by ", abs(contrastReduction), "%"
    
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
    echo "Usage: ", paramStr(0), " <input_image> <output_image> [brightness_reduction%] [contrast_reduction%]"
    echo "Example: ", paramStr(0), " input.jpg output.jpg 10 20"
    echo "Default: reduces brightness by 10% and contrast by 20%"
    echo "Note: Image will be cropped to a square using the smaller dimension"
    quit(1)
  
  let inputPath = paramStr(1)
  let outputPath = paramStr(2)
  let brightnessReduction = if paramCount() >= 3: -parseFloat(paramStr(3)) else: -10.0
  let contrastReduction = if paramCount() >= 4: -parseFloat(paramStr(4)) else: -20.0
  
  adjustImageBrightnessContrast(inputPath, outputPath, brightnessReduction, contrastReduction)
