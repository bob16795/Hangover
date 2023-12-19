import types/sfx
import types/song
import types/vector2
import random
import openal
import hangover/core/logging
import options

const
  SOURCES = 30

var
  device: ALCdevice
  audioCtx: ALCcontext

  # sources
  musicSources: array[MAX_SONG_LAYERS, ALuint]
  musicActive: array[MAX_SONG_LAYERS, bool]
  musicVols: array[MAX_SONG_LAYERS, float32]
  soundSources: array[SOURCES, ALuint]

  nextSoundSource: int = 0
  loopBuffers: array[MAX_SONG_LAYERS, ALuint]
  alPaused: bool

  masterVol: float32 = 1.0


proc initAudio*() {.exportc, cdecl, dynlib.} =
  ## sets up the audio system
  let
    devicename = alcGetString(nil, ALC_DEFAULT_DEVICE_SPECIFIER);

  device = alcOpenDevice(devicename)
  if device == nil: LOG_CRITICAL "ho->audio", "OpenAL: failed to get default device"
  #let tmp = [ALC_FREQUENCY.ALint, 44100, 0]
  audioCtx = device.alcCreateContext(nil) # unsafeAddr tmp[0])
  if audioCtx == nil: LOG_CRITICAL "ho->audio", "OpenAL: failed to create context"
  if not alcMakeContextCurrent(audioCtx): LOG_CRITICAL "ho->audio", "OpenAL: failed to make context current"

  # generate song source
  alGenSources(ALsizei MAX_SONG_LAYERS, addr musicSources[0])

  # geenrate sound sources
  alGenSources(ALsizei SOURCES, addr soundSources[0])

  # set default music data
  musicVols[0] = 1.0
  masterVol = 1.0
    
  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->audio", "openAl error init", $e)

proc pauseAudio*() {.exportc, cdecl, dynlib.} =
  if alPaused: return 
  for musicSource in musicSources:
    alSourcePause(musicSource)
  alPaused = true

proc playAudio*() {.exportc, cdecl, dynlib.} =
  if not alPaused: return 
  for musicSource in musicSources:
    alSourcePlay(musicSource)
  alPaused = false

proc setVolume*(vol: float32, music: bool) =
  if music:
    for idx in 0..<len musicSources:
      alSourcef(musicSources[idx], AL_GAIN, ALfloat vol * musicVols[idx])
    masterVol = vol
  else:
    for s in soundSources:
      alSourcef(s, AL_GAIN, ALfloat vol)

proc updateAudio*() =
  ## updates audio
  ## checks if music should loop
  ## checks for openAL errors
  if alPaused: return
  var sourceState: ALint
  alGetSourcei(musicSources[0], AL_SOURCE_STATE, addr sourceState)
  if sourceState != AL_PLAYING:
    for idx in 0..<len musicSources:
      if not musicActive[idx]: continue
      if loopBuffers[idx] == 0: continue
      alSourcei(musicSources[idx], AL_BUFFER, Alint loopBuffers[idx])
      alSourcei(musicSources[idx], AL_LOOPING, 1)
      alSourcePlay(musicSources[idx])
  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->audio", "openAl error", $e)

proc play*(song: Song) =
  ## plays a song
  if song.layers[0].get().loopBuffer == loopBuffers[0]: return

  for idx in 0..<musicSources.len:
    musicActive[idx] = false
    alSourcef(musicSources[idx], AL_PITCH, 1.0.float32)
    loopBuffers[idx] = 0
    if song.layers[idx].isNone():
      alSourcei(musicSources[idx], AL_BUFFER, Alint 0)
      alSourcef(musicSources[idx], AL_GAIN, ALfloat 0.0)
      alSourceStop(musicSources[idx])
      musicVols[idx] = 0.0
      continue
    musicVols[idx] = if idx == 0: 1.0 else: 0.0
    alSourcef(musicSources[idx], AL_GAIN, ALfloat masterVol * musicVols[idx])
    musicActive[idx] = true

    if song.hasIntro:
      alSourceStop(musicSources[idx])
      alSourcei(musicSources[idx], AL_BUFFER, Alint song.layers[idx].get().introBuffer)
      alSourcei(musicSources[idx], AL_LOOPING, 0)
      alSourcePlay(musicSources[idx])
    else:
      alSourceStop(musicSources[idx])
      alSourcei(musicSources[idx], AL_BUFFER, Alint song.layers[idx].get().loopBuffer)
      alSourcei(musicSources[idx], AL_LOOPING, 1)
      alSourcePlay(musicSources[idx])
    loopBuffers[idx] = song.layers[idx].get().loopBuffer

proc setLayerVolume*(layer: range[0..MAX_SONG_LAYERS-1], vol: float32) =
  if not musicActive[layer]: return
  alSourcef(musicSources[layer], AL_GAIN, ALfloat masterVol * musicVols[layer])
  musicVols[layer] = vol

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
  alSource3f(soundSources[nextSoundSource], AL_POSITION, pos.x * 0.1, pos.y * 0.1, 0)
  
  # play the sound
  alSourcePlay(soundSources[nextSoundSource])
  
  # loop the source
  nextSoundSource += 1
  if nextSoundSource == SOURCES:
    nextSoundSource = 0
