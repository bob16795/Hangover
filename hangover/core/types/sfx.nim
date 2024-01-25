import openal
import streams
import ../lib/readwav
import hangover/core/logging

type
  Sound* = ref object
    ## stores a sound effect
    valid*: bool
    buffer*: ALuint ## the al buffer

proc newSoundMem*(s: Stream): Sound =
  ## creates a new sound from a stream

  result = Sound()

  # read the wav file
  let wav = readWav(s)
  s.close()

  # create a buffer and add data
  alGenBuffers(ALsizei 1, addr result.buffer)
  alBufferData(result.buffer, AL_FORMAT_MONO16, wav.data, ALsizei wav.size,
      ALsizei wav.freq)
  result.valid = true

  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->sfx", "openAl error", $e)

proc newSound*(file: string): Sound =
  ## creates a sound from file

  # create a stream
  let s = newFileStream(file)

  # get data
  result = newSoundMem(s)
