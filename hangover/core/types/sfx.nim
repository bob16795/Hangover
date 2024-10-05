import openal
import streams
import ../lib/readwav
import ../lib/vorbis
import hangover/core/logging

type
  Sound* = ref object
    ## stores a sound effect
    buffer*: ALuint ## the al buffer

proc newSoundMem*(s: Stream, ogg: bool = false): Sound =
  ## creates a new sound from a stream

  result = Sound()

  # read the wav file
  let wav = if ogg:
              loadVorbis(s.readAll())
            else:
              readWav(s)
  s.close()

  # create a buffer and add data
  alGenBuffers(ALsizei 1, addr result.buffer)
  alBufferData(result.buffer, AL_FORMAT_MONO16, wav.data, ALsizei wav.size,
      ALsizei wav.freq)

  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->sfx", "openAl error", $e)

proc newSound*(file: string): Sound =
  ## creates a sound from file

  # create a stream
  let s = newFileStream(file)

  # get data
  result = newSoundMem(s)

proc freeSound*(s: Sound) =
  alDeleteBuffers(ALsizei 1, addr s.buffer)
