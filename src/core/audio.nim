import types/sound
import types/song

import openal
import random

const
  SOURCES = 30

var
  device: ALCdevice
  audioCtx: ALCcontext

  # sources
  musicSource: ALuint
  soundSources: array[0..(SOURCES - 1), ALuint]

  nextSoundSource: int = 0

proc initAudio*() =
  device = alcOpenDevice(nil)
  if device == nil: quit "OpenAL: failed to get default device"
  audioCtx = device.alcCreateContext(nil)
  if audioCtx == nil: quit "OpenAL: failed to create context"
  if not alcMakeContextCurrent(audioCtx): quit "OpenAL: failed to make context current"

  # generate song source
  alGenSources(ALsizei 1, addr musicSource)
  alSourcei(musicSource, AL_LOOPING, 1)

  # geenrate sound sources
  alGenSources(ALsizei SOURCES, addr soundSources[0])

proc play*(song: Song) =
  # play sound
  alSourcei(musicSource, AL_BUFFER, Alint song.buffer)
  alSourcePlay(musicSource)

proc play*(sound: Sound) =
  # play sound
  alSourcef(soundSources[nextSoundSource], AL_PITCH, 1.0.float32)
  alSourcei(soundSources[nextSoundSource], AL_BUFFER, Alint sound.buffer)
  alSourcePlay(soundSources[nextSoundSource])
  nextSoundSource += 1
  if nextSoundSource == SOURCES:
    nextSoundSource = 0

proc playRand*(sound: Sound, rs, re: float32) =
  alSourcef(soundSources[nextSoundSource], AL_PITCH, rand(rs..re).float32)
  alSourcei(soundSources[nextSoundSource], AL_BUFFER, Alint sound.buffer)
  alSourcePlay(soundSources[nextSoundSource])
  nextSoundSource += 1
  if nextSoundSource == SOURCES:
    nextSoundSource = 0
