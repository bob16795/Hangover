import openal
import ../lib/readwav

type
  Song* = object
    buffer*: ALuint

proc newSong*(file: string): Song =
  var wav = readWav(file)
  alGenBuffers(ALsizei 1, addr result.buffer)
  alBufferData(result.buffer, AL_FORMAT_STEREO16, wav.data, ALsizei wav.size,
      ALsizei wav.freq)
