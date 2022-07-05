import openal
import streams
import ../lib/readwav

# TODO: comment

type
  Sound* = object
    buffer*: ALuint

proc newSoundMem*(s: Stream): Sound =
  var wav = readWav(s)
  alGenBuffers(ALsizei 1, addr result.buffer)
  alBufferData(result.buffer, AL_FORMAT_MONO16, wav.data, ALsizei wav.size,
      ALsizei wav.freq)
  s.close()

proc newSound*(file: string): Sound =
  var s = newFileStream(file)
  result = newSoundMem(s)
