
when defined(windows) and defined(vcc):
  {.pragma: stbcall, stdcall.}
else:
  {.pragma: stbcall, cdecl.}

# Include the header
{.compile: "stbi.c".}

proc stbi_load*(
  filename: cstring;
  x, y, channels_in_file: var cint;
  desired_channels: cint
): pointer
  {.importc: "stbi_load", stbcall.}

proc stbi_load_from_memory*(
  buffer: ptr cuchar;
  len: cint;
  x, y, channels_in_file: var cint;
  desired_channels: cint
): pointer
  {.importc: "stbi_load_from_memory", stbcall.}

proc stbi_image_free*(retval_from_stbi_load: pointer)
  {.importc: "stbi_image_free", stbcall.}
