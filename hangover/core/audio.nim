import types/sfx
import types/song
import types/vector2
import random
import openal
import hangover/core/logging

const
  SOURCES = 30

var
  device: ALCdevice
  audioCtx: ALCcontext

  # sources
  musicSource: ALuint
  soundSources: array[0..(SOURCES - 1), ALuint]

  nextSoundSource: int = 0
  loopBuffer: ALuint
  alPaused: bool

  musicVol: float32


proc initAudio*() {.exportc, cdecl, dynlib.} =
  ## sets up the audio system
  var
    devicename = alcGetString(nil, ALC_DEFAULT_DEVICE_SPECIFIER);

  device = alcOpenDevice(devicename);
  if device == nil: LOG_CRITICAL "ho->audio", "OpenAL: failed to get default device"
  audioCtx = device.alcCreateContext(nil)
  if audioCtx == nil: LOG_CRITICAL "ho->audio", "OpenAL: failed to create context"
  if not alcMakeContextCurrent(audioCtx): LOG_CRITICAL "ho->audio", "OpenAL: failed to make context current"


  # generate song source
  alGenSources(ALsizei 1, addr musicSource)

  # geenrate sound sources
  alGenSources(ALsizei SOURCES, addr soundSources[0])

proc pauseAudio*() {.exportc, cdecl, dynlib.} =
  alSourcePause(musicSource)
  alPaused = true

proc playAudio*() {.exportc, cdecl, dynlib.} =
  alSourcePlay(musicSource)
  alPaused = false

proc setVolume*(vol: float32, music: bool) =
  if music:
    alSourcef(musicSource, AL_GAIN, ALfloat vol)
  else:
    for s in soundSources:
      alSourcef(s, AL_GAIN, ALfloat vol)

proc updateAudio*() =
  ## updates audio
  ## checks if music should loop
  ## checks for openAL errors
  if alPaused: return
  var sourceState: ALint
  alGetSourcei(musicSource, AL_SOURCE_STATE, addr sourceState)
  if (sourceState != AL_PLAYING and loopBuffer != 0):
    alSourcei(musicSource, AL_BUFFER, Alint loopBuffer)
    alSourcei(musicSource, AL_LOOPING, 1)
    alSourcePlay(musicSource)
  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->audio", "openAl error", $e)


proc play*(song: Song) =
  ## plays a song
  if song.loopBuffer == loopBuffer: return
  alSourcef(musicSource, AL_PITCH, 1.0.float32)
  if song.hasIntro:
    alSourceStop(musicSource)
    alSourcei(musicSource, AL_BUFFER, Alint song.introbuffer)
    alSourcei(musicSource, AL_LOOPING, 0)
    alSourcePlay(musicSource)
  else:
    alSourceStop(musicSource)
    discard
  loopBuffer = song.loopBuffer

proc play*(sound: Sound, pos: Vector2 = newVector2(0, 0), pitch: float32 = 1.0) =
  ## plays a sound, pos is for spacial sound
  var sourceState: ALint
  alGetSourcei(soundSources[nextSoundSource], AL_SOURCE_STATE, addr sourceState)
  if sourceState != AL_PLAYING:
    alSourcef(soundSources[nextSoundSource], AL_PITCH, pitch)
    alSourcei(soundSources[nextSoundSource], AL_BUFFER, Alint sound.buffer)
    alSource3f(soundSources[nextSoundSource], AL_POSITION, pos.x, pos.y, 0)
    alSourcePlay(soundSources[nextSoundSource])
  nextSoundSource += 1
  if nextSoundSource == SOURCES:
    nextSoundSource = 0

proc playRand*(sound: Sound, rs, re: float32, pos: Vector2 = newVector2(0, 0)) =
  ## plays a sound at a random pitch
  
  # set pitch, buffer and position
  alSourcef(soundSources[nextSoundSource], AL_PITCH, rand(rs..re).float32)
  alSourcei(soundSources[nextSoundSource], AL_BUFFER, Alint sound.buffer)
  alSource3f(soundSources[nextSoundSource], AL_POSITION, pos.x, pos.y, 0)
  
  # play the sound
  alSourcePlay(soundSources[nextSoundSource])
  
  # loop the source
  nextSoundSource += 1
  if nextSoundSource == SOURCES:
    nextSoundSource = 0
