import openal
import streams
import ../lib/readwav

# TODO: comment

type
  Song* = object
    hasIntro*: bool
    introbuffer*: ALuint
    loopBuffer*: ALuint

template `+`(p: pointer, off: int): pointer =
  cast[pointer](cast[ByteAddress](p) +% off * sizeof(uint8))


proc newSongMem*(s: Stream, loopPoint: float32 = 0): Song =
  var wav = readWav(s)
  if loopPoint != 0:
    result.hasIntro = true
    alGenBuffers(ALsizei 1, addr result.introbuffer)
    alBufferData(result.introbuffer, AL_FORMAT_STEREO16, wav.data, ALsizei wav.size,
        ALsizei wav.freq)
    var start = ((wav.size.float32 / 4) * loopPoint).int * 4
    alGenBuffers(ALsizei 1, addr result.loopBuffer)
    alBufferData(result.loopBuffer, AL_FORMAT_STEREO16, wav.data + start, ALsizei((wav.size - start).int),
        ALsizei wav.freq)
  else:
    alGenBuffers(ALsizei 1, addr result.loopBuffer)
    alBufferData(result.loopBuffer, AL_FORMAT_STEREO16, wav.data, ALsizei wav.size,
        ALsizei wav.freq)
  s.close()

proc newSong*(file: string, loopPoint: float32 = 0): Song =
  var s = newFileStream(file)
  result = newSongMem(s)
