import openal
import ../lib/readwav

type
  Sound* = object
    buffer*: ALuint

proc newSound*(file: string): Sound =
  var wav = readWav(file)
  alGenBuffers(ALsizei 1, addr result.buffer)
  alBufferData(result.buffer, AL_FORMAT_MONO16, wav.data, ALsizei wav.size,
      ALsizei wav.freq)
