import openal
import streams
import options
import ../lib/readwav
import ../lib/vorbis
import hangover/core/logging
import async

# TODO: comment
const MAX_SONG_LAYERS* = 5

type
  SongLayer* = object
    loopBuffer*: ALuint
    introBuffer*: ALuint

  Song* = object
    hasIntro*: bool
    loopPoint: float32
    baseLen: int
    layers*: array[MAX_SONG_LAYERS, Option[SongLayer]]

template `+`(p: pointer, off: int): pointer =
  cast[pointer](cast[ByteAddress](p) +% off * sizeof(uint8))

proc newSongMem*(s: Stream, loopPoint: float32 = 0, ogg = false): Song =
  let wav = if ogg:
              loadVorbis(s.readAll())
            else:
              readWav(s)

  var baseLayer: SongLayer

  if loopPoint != 0:
    let start = ((wav.size.float32 / 32) * clamp(loopPoint, 0, 1)).int * 32

    result.hasIntro = true
    alGenBuffers(ALsizei 1, addr baseLayer.introbuffer)
    alBufferData(baseLayer.introbuffer, AL_FORMAT_STEREO16, wav.data, ALsizei start,
        ALsizei wav.freq)
    alGenBuffers(ALsizei 1, addr baseLayer.loopBuffer)
    alBufferData(baseLayer.loopBuffer, AL_FORMAT_STEREO16, wav.data + start, ALsizei((wav.size - start).int),
        ALsizei wav.freq)
  else:
    alGenBuffers(ALsizei 1, addr baseLayer.loopBuffer)
    alBufferData(baseLayer.loopBuffer, AL_FORMAT_STEREO16, wav.data, ALsizei wav.size,
        ALsizei wav.freq)
  result.layers[0] = some(baseLayer)
  result.baseLen = wav.size
  result.loopPoint = loopPoint

  s.close()

  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->song", "openAl error", $e)

proc addLayer*(song: var Song, s: Stream, idx: range[0..MAX_SONG_LAYERS - 1]) =
  let wav = readWav(s)
  var baseLayer: SongLayer

  if wav.size != song.baseLen:
    LOG_ERROR "ho->song", "could not add incorrectly sized layer to song"

    return

  if song.loopPoint != 0:
    alGenBuffers(ALsizei 1, addr baseLayer.introbuffer)
    alBufferData(baseLayer.introbuffer, AL_FORMAT_STEREO16, wav.data, ALsizei wav.size,
        ALsizei wav.freq)
    let start = ((wav.size.float32 / 32) * song.loopPoint).int * 32
    alGenBuffers(ALsizei 1, addr baseLayer.loopBuffer)
    alBufferData(baseLayer.loopBuffer, AL_FORMAT_STEREO16, wav.data + start, ALsizei((wav.size - start).int),
        ALsizei wav.freq)
  else:
    alGenBuffers(ALsizei 1, addr baseLayer.loopBuffer)
    alBufferData(baseLayer.loopBuffer, AL_FORMAT_STEREO16, wav.data, ALsizei wav.size,
        ALsizei wav.freq)
  song.layers[idx] = some(baseLayer)

  s.close()

proc newSong*(file: string, loopPoint: float32 = 0, ogg = false): Song =
  let s = newFileStream(file)
  result = newSongMem(s, loopPoint, ogg)
