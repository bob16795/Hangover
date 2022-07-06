import streams

type WavFile* = object
  ## stores PCM data
  data*: pointer
  size*: int
  freq*: int
  channels*: int

proc readWav*(
  f: Stream,
  ): WavFile =
  ## load PCM data from wav file
  let chunkID = f.readStr(4)
  discard f.readUint32()
  let format = f.readStr(4)
  let subchunk1ID = f.readStr(4)
  discard f.readUint32()
  let audioFormat = f.readUint16()
  let numChannels = f.readUint16()
  let sampleRate = f.readUint32()
  discard f.readUint32()
  discard f.readUint16()
  discard f.readUint16()
  var subchunk2ID = f.readStr(4)
  var subchunk2Size = f.readUint32()
  var data = f.readStr(int subchunk2Size)

  if subchunk2ID == "LIST":
    subchunk2ID = f.readStr(4)
    subchunk2Size = f.readUint32()
    data = f.readStr(int subchunk2Size)

  # make sure wav file
  assert chunkID == "RIFF"
  assert format == "WAVE"
  assert subchunk1ID == "fmt "
  assert audioFormat == 1
  assert subchunk2ID == "data"

  result.channels = int numChannels
  result.size = data.len
  result.freq = int sampleRate
  result.data = unsafeAddr data[0]
