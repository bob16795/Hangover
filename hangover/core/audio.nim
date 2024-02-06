import types/sfx
import types/song
import types/vector2
import random
import openal
import hangover/core/logging
import options

const
  SOURCES = 60

type
  SongQueueEntry = ref object
    song: Song
    skip: bool

var
  device: ALCdevice
  audioCtx: ALCcontexT

  # sources
  musicSources: array[MAX_SONG_LAYERS, ALuint]
  musicActive: array[MAX_SONG_LAYERS, bool]
  musicVols: array[MAX_SONG_LAYERS, float32]
  soundSources: array[SOURCES, ALuint]

  nextSoundSource: uint = 0
  loopBuffers: array[MAX_SONG_LAYERS, ALuint]
  alPaused: bool
  framePlayed: seq[Sound]

  masterVol: float32 = 1.0
  audioSize*: Vector2 = newVector2(1.0, 1.0)
  songQueue: seq[SongQueueEntry]

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

proc getSongLooping*(): bool =
  # gets how many songs are queued
  var looping, playing: ALint
  alGetSourcei(musicSources[0], AL_LOOPING, addr looping)
  return looping != 0

proc getSongQueueSize*(): int =
  # gets how many songs are queued
  result = songQueue.len

proc play*(song: Song, force: bool = false, skip: bool = false, inQueue: bool = false) =
  ## plays a song
  if not force and song.layers[0].get().loopBuffer == loopBuffers[0]: return

  var looping, playing: ALint
  alGetSourcei(musicSources[0], AL_LOOPING, addr looping)
  alGetSourcei(musicSources[0], AL_SOURCE_STATE, addr playing)
  if not inQueue and not force and skip and looping == 0 and playing == AL_PLAYING:
    songQueue &= SongQueueEntry(
      song: song,
      skip: skip,
    )
    return

  if force:
    songQueue = @[]

  for idx in 0..<musicSources.len:
    var offset: ALfloat

    alGetSourcef(musicSources[idx], AL_SEC_OFFSET, addr offset)
    alSourceStop(musicSources[idx])

    musicActive[idx] = false
    alSourcef(musicSources[idx], AL_PITCH, 1.0.float32)
    loopBuffers[idx] = 0
    if song.layers[idx].isNone():
      alSourcei(musicSources[idx], AL_BUFFER, Alint 0)
      musicVols[idx] = 0.0
      continue
    musicVols[idx] = if idx == 0: 1.0 else: 0.0
    musicActive[idx] = true

    if song.hasIntro:
      alSourcei(musicSources[idx], AL_BUFFER, Alint song.layers[idx].get().introBuffer)
      alSourcei(musicSources[idx], AL_LOOPING, 0)
    else:
      alSourcei(musicSources[idx], AL_BUFFER, Alint song.layers[idx].get().loopBuffer)
      alSourcei(musicSources[idx], AL_LOOPING, 1)

    alSourcef(musicSources[idx], AL_GAIN, ALfloat masterVol * musicVols[idx])
    alSourcePlay(musicSources[idx])

    if skip:
      alSourcef(musicSources[idx], AL_SEC_OFFSET, offset)

    loopBuffers[idx] = song.layers[idx].get().loopBuffer

proc setLayerVolume*(layer: range[0..MAX_SONG_LAYERS-1], vol: float32) =
  if not musicActive[layer]: return
  alSourcef(musicSources[layer], AL_GAIN, ALfloat masterVol * musicVols[layer])
  musicVols[layer] = vol

proc setMusicSpeed*(speed: float32) =
  for m in musicSources:
    alSourcef(m, AL_PITCH, speed)

proc play*(sound: Sound, pos: Vector2 = newVector2(0, 0), pitch: float32 = 1.0) =
  ## plays a sound, pos is for spacial sound
  if sound in framePlayed:
    return
  framePlayed &= sound
  var sourceState: ALint
  alGetSourcei(soundSources[nextSoundSource mod SOURCES], AL_SOURCE_STATE, addr sourceState)
  if sourceState != AL_PLAYING:
    alSourcef(soundSources[nextSoundSource mod SOURCES], AL_PITCH, pitch)
    alSourcei(soundSources[nextSoundSource mod SOURCES], AL_BUFFER, Alint sound.buffer)
    alSource3f(soundSources[nextSoundSource mod SOURCES], AL_POSITION, pos.x / audioSize.x.float32, pos.y / audioSize.y.float32, 0)

    let e = alGetError()
    if e != AL_NO_ERROR:
      LOG_ERROR("ho->audio", "openAl error playRand", $e)
      return

    alSourcePlay(soundSources[nextSoundSource mod SOURCES])
  nextSoundSource += 1

proc playRand*(sound: Sound, r: HSlice[float32, float32], pos: Vector2 = newVector2(0, 0)) =
  ## plays a sound at a random pitch
  if sound in framePlayed:
    return
  framePlayed &= sound

  var sourceState: ALint
  
  # set pitch, buffer and position
  alGetSourcei(soundSources[nextSoundSource mod SOURCES], AL_SOURCE_STATE, addr sourceState)
  if sourceState != AL_PLAYING:
    alSourcef(soundSources[nextSoundSource mod SOURCES], AL_PITCH, rand(r).float32)
    alSourcei(soundSources[nextSoundSource mod SOURCES], AL_BUFFER, Alint sound.buffer)
    alSource3f(soundSources[nextSoundSource mod SOURCES], AL_POSITION, -pos.x / audioSize.x.float32, pos.y / audioSize.y.float32, 0)
    let e = alGetError()
    if e != AL_NO_ERROR:
      LOG_ERROR("ho->audio", "openAl error playRand", $e)
      return
  
    # play the sound
    alSourcePlay(soundSources[nextSoundSource mod SOURCES])
  
  # loop the source
  nextSoundSource += 1

proc playRand*(sound: Sound, rs, re: float32, pos: Vector2 = newVector2(0, 0)) {.deprecated.} =
  playRand(sound, rs..re, pos)

proc updateAudio*() =
  ## updates audio
  ## checks if music should loop
  ## checks for openAL errors
  framePlayed = @[]
  if alPaused: return
  var sourceState: ALint
  alGetSourcei(musicSources[0], AL_SOURCE_STATE, addr sourceState)
  if sourceState != AL_PLAYING:
    for idx in 0..<len musicSources:
      if not musicActive[idx]: continue
      if loopBuffers[idx] == 0: continue
      if songQueue.len > 0:
        let q = songQueue[0]
        songQueue.delete(0)
        q.song.play(q.skip, inQueue = true)
      else:
        alSourcei(musicSources[idx], AL_BUFFER, Alint loopBuffers[idx])
        alSourcei(musicSources[idx], AL_LOOPING, 1)
        alSourcePlay(musicSources[idx])
  let e = alGetError()
  if e != AL_NO_ERROR:
    LOG_ERROR("ho->audio", "openAl error", $e)
