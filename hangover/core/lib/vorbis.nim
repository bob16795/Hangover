{.compile: "vorbis.c".}

# Stole this from treeform slappy

import readwav

type
  Vorbis = ptr object
  VorbisInfo = object
    sample_rate: cuint
    channels: cint
    setup_memory_required: cuint
    setup_temp_memory_required: cuint
    temp_memory_required: cuint
    max_frame_size: cint

proc stb_vorbis_open_memory(
  data: pointer,
  len: cint,
  error: ptr cint,
  alloc_buffer: pointer
): Vorbis {.importc, noconv.}
proc stb_vorbis_get_info(f: Vorbis): VorbisInfo {.importc, noconv.}
proc stb_vorbis_stream_length_in_samples(f: Vorbis): cuint {.importc, noconv.}
proc stb_vorbis_get_samples_short_interleaved(
  f: Vorbis,
  channels: cint,
  buffer: pointer,
  num_shorts: cint
): cint {.importc, noconv.}
proc stb_vorbis_close(f: Vorbis) {.importc, noconv.}

proc loadVorbis*(
  data: string,
): WavFile =
  ## Reads and decodes a whole ogg file.

  # get vorbis context
  var vorbisCtx = stb_vorbis_open_memory(addr data[0], cint(data.len), nil, nil)
  if vorbisCtx == nil:
    raise newException(
      ValueError,
      "Decoding Vorbis file failed"
    )

  # get vorbis info
  let vorbisInfo = stb_vorbis_get_info(vorbisCtx)
  const bytesPerSample = 2
  let channels = vorbisInfo.channels

  # get num samples
  let numSamples = stb_vorbis_stream_length_in_samples(vorbisCtx)
  result.size = numSamples.int * channels.int * bytesPerSample.int

  # allocate primary buffer
  result.data = alloc(result.size)

  # decode whole file at once
  let dataRead = stb_vorbis_get_samples_short_interleaved(
    vorbisCtx,
    vorbisInfo.channels,
    result.data,
    cint(numSamples * cuint(channels))
  ) * channels * bytesPerSample

  # make sure the decode was successful
  if dataRead.int != result.size:
    raise newException(
      ValueError,
      "Decoding Vorbis file failed, unable to read entire file"
    )
  elif dataRead == 0:
    raise newException(
      ValueError,
      "Decoding Vorbis file failed"
    )

  # prepare the result
  result.freq = int(vorbisInfo.sampleRate)
  result.channels = vorbisInfo.channels

  # close the reader context
  stb_vorbis_close(vorbisCtx)
