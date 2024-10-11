import types/sfx
import types/song
import types/vector2
import random
import openal
import hangover/core/logging
import options

const
  SOURCES = 30

type
  SongQueueEntry = ref object
    song: Song
    skip: bool
  SfxQueueEntry = object
    sound: Sound
    pos: Vector2
    pitch: float32

  VolumeEntry* = enum
    volMaster
    volMusic
    volSfx

  AudioError* = object of CatchableError 

var
  device: ALCdevice
  audioCtx: ALCcontext

  # sources
  musicSources: array[MAX_SONG_LAYERS, ALuint]
  musicActive: array[MAX_SONG_LAYERS, bool]
  musicTargVols: array[MAX_SONG_LAYERS, float32]
  musicVols: array[MAX_SONG_LAYERS, float32]
  musicFade: float32
  soundSources: array[SOURCES, ALuint]

  sfxQueue: seq[SfxQueueEntry]

  nextSoundSource: uint = 0
  loopBuffers: array[MAX_SONG_LAYERS, ALuint]
  alPaused: bool
  framePlayed: seq[Sound]

  audioSize*: Vector2 = newVector2(1.0, 1.0)
  songQueue: seq[SongQueueEntry]

  volume: array[VolumeEntry, float32]

  stereo: bool

proc checkAudioErr*(name: string) {.inline.} =
  let e = alGetError()
  if e != AL_NO_ERROR:
    raise newException(AudioError, name & " " & $e)

proc initAudio*() {.exportc, cdecl, dynlib.} =
  ## sets up the audio system
  try:
    let
      devicename = alcGetString(nil, ALC_DEFAULT_DEVICE_SPECIFIER);
    
    device = alcOpenDevice(devicename)

    if device == nil:
      raise newException(AudioError, "Failed to get default audio device") 

    audioCtx = device.alcCreateContext(nil)

    if audioCtx == nil:
      raise newException(AudioError, "Failed to create openal context") 

    if not alcMakeContextCurrent(audioCtx):
      raise newException(AudioError, "Failed to use openal context") 

    # generate song source
    alGenSources(ALsizei MAX_SONG_LAYERS, addr musicSources[0])

    # geenrate sound sources
    alGenSources(ALsizei SOURCES, addr soundSources[0])

    # set default music data
    musicTargVols[0] = 1.0
    musicVols[0] = 1.0
    for v in VolumeEntry.low..VolumeEntry.high:
      volume[v] = 1.0
  finally:
    while alGetError() != AL_NO_ERROR:
      discard

proc setStereo*(value: bool) =
  stereo = value

proc pauseAudio*() {.exportc, cdecl, dynlib.} =
  if alPaused: return
  for musicSource in musicSources:
    alSourcePause(musicSource)
    checkAudioErr("sourcePause (pauseAudio)")

  alPaused = true

proc playAudio*() {.exportc, cdecl, dynlib.} =
  if not alPaused: return
  for musicSource in musicSources:
    alSourcePlay(musicSource)
    checkAudioErr("sourcePlay (playAudio)")
  alPaused = false

proc setVolume*(vol: float32, kind: VolumeEntry) =
  volume[kind] = vol.clamp(0, 1)

  case kind:
  of volMusic:
    for layer in 0 ..< musicSources.len:
      alSourcef(musicSources[layer], AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicVols[layer] * musicFade)
      checkAudioErr("alSourcef (gain setVol)")
  of volMaster:
    for layer in 0 ..< musicSources.len:
      alSourcef(musicSources[layer], AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicVols[layer] * musicFade)
      checkAudioErr("alSourcef (gain setVol)")
    for s in soundSources:
      alSourcef(s, AL_GAIN, ALfloat volume[volMaster] * volume[volSfx])
      checkAudioErr("alSourcef (gain setVol)")
  of volSfx:
    for s in soundSources:
      alSourcef(s, AL_GAIN, ALfloat volume[volMaster] * volume[volSfx])
      checkAudioErr("alSourcef (gain setVol)")

proc getSongLooping*(): bool =
  # gets how many songs are queued
  var looping: ALint
  alGetSourcei(musicSources[0], AL_LOOPING, addr looping)
  checkAudioErr("getSourceI (loop, getSongLooping)")

  return looping != 0

proc getSongQueueSize*(): int =
  # gets how many songs are queued
  result = songQueue.len

proc play*(
  song: Song,
  fade: bool = false,
  force: bool = false,
  skip: bool = false,
  inQueue: bool = false) =
  ## plays a song
  if song.layers[0].get().loopBuffer == loopBuffers[0]: return

  var looping, playing: ALint
  alGetSourcei(musicSources[0], AL_LOOPING, addr looping)
  checkAudioErr("getSourcei")
  alGetSourcei(musicSources[0], AL_SOURCE_STATE, addr playing)
  checkAudioErr("getSorucei")
  if not inQueue and not force and skip and looping == 0 and playing == AL_PLAYING:
    songQueue &= SongQueueEntry(
      song: song,
      skip: skip,
    )
    return

  if force:
    songQueue = @[]

  if fade:
    musicFade = 0.0

  for idx in 0..<musicSources.len:
    var offset: ALfloat

    alGetSourcef(musicSources[idx], AL_SEC_OFFSET, addr offset)
    checkAudioErr("getSourcef")
    alSourceStop(musicSources[idx])
    checkAudioErr("sourceStop")

    musicActive[idx] = false
    alSourcef(musicSources[idx], AL_PITCH, 1.0.float32)
    checkAudioErr("sourcef")
    loopBuffers[idx] = 0
    if song.layers[idx].isNone():
      alSourcei(musicSources[idx], AL_BUFFER, Alint 0)
      checkAudioErr("sourcei")
      musicTargVols[idx] = 0.0
      continue
    musicTargVols[idx] = if idx == 0: 1.0 else: 0.0
    musicActive[idx] = true

    if song.hasIntro:
      alSourcei(musicSources[idx], AL_BUFFER, Alint song.layers[idx].get().introBuffer)
      checkAudioErr("sourcei")
      alSourcei(musicSources[idx], AL_LOOPING, 0)
      checkAudioErr("sourcei")
    else:
      alSourcei(musicSources[idx], AL_BUFFER, Alint song.layers[idx].get().loopBuffer)
      checkAudioErr("sourcei")
      alSourcei(musicSources[idx], AL_LOOPING, 1)
      checkAudioErr("sourcei")

    alSourcef(musicSources[idx], AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicVols[idx] * musicFade)
    checkAudioErr("sourcef")
    alSourcePlay(musicSources[idx])
    checkAudioErr("sourcePlay")

    if skip:
      alSourcef(musicSources[idx], AL_SEC_OFFSET, offset)
      checkAudioErr("sourcef")

    loopBuffers[idx] = song.layers[idx].get().loopBuffer

proc setLayerVolume*(layer: range[0..MAX_SONG_LAYERS-1], vol: float32, force: bool = false) =
  if not musicActive[layer]: return
  musicTargVols[layer] = vol
  if force:
    musicVols[layer] = vol
    alSourcef(musicSources[layer], AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicVols[layer] * musicFade)
    checkAudioErr("sourcef")

proc setMusicSpeed*(speed: float32) =
  for m in musicSources:
    alSourcef(m, AL_PITCH, speed)
    checkAudioErr("sourcef")

proc play*(sound: Sound, pos: Vector2 = newVector2(0, 0),
    pitch: float32 = 1.0) =
  ## plays a sound, pos is for spacial sound
  if sound == nil:
    return

  if sound in framePlayed:
    return
  framePlayed &= sound
  var sourceState: ALint
  nextSoundSource += 1

  let source = soundSources[nextSoundSource mod SOURCES]

  alGetSourcei(source, AL_SOURCE_STATE,
    addr sourceState)
  checkAudioErr("sourcei")
  alSourceStop(source)
  checkAudioErr("sourceStop")
  alSourceRewind(source)
  checkAudioErr("sourceRewind")
  alSourcef(source, AL_PITCH, pitch.clamp(0, 10.0))
  checkAudioErr("sourcef")
  alSourcei(source, AL_BUFFER, Alint sound.buffer)
  checkAudioErr("sourcei")
  if stereo:
    alSource3f(
      source,
      AL_POSITION,
      (pos.x / audioSize.x.float32).clamp(-1, 1),
      (pos.y / audioSize.y.float32).clamp(-1, 1),
      0
    )
    checkAudioErr("source3f")
  else:
    alSource3f(
      source,
      AL_POSITION,
      0,
      0,
      0,
    )
    checkAudioErr("source3f")

  alSourcePlay(soundSources[nextSoundSource mod SOURCES])
  checkAudioErr("sourcePlay")

proc playRand*(sound: Sound, r: HSlice[float32, float32],
    pos: Vector2 = newVector2(0, 0)) =
  ## plays a sound at a random pitch
  play(sound, pos, rand(r))

proc playRand*(sound: Sound, rs, re: float32, pos: Vector2 = newVector2(0,
    0)) {.deprecated.} =
  playRand(sound, rs..re, pos)

proc updateAudio*(dt: float32) =
  ## updates audio
  ## checks if music should loop
  ## checks for openAL errors
  framePlayed = @[]
  if alPaused: return

  for layer in 0..<musicSources.len:
    if musicTargVols[layer] < musicVols[layer]:
      musicVols[layer] -= dt * 0.5
      musicVols[layer] = max(musicTargVols[layer], musicVols[layer])
    elif musicTargVols[layer] > musicVols[layer]:
      musicVols[layer] += dt * 0.5
      musicVols[layer] = min(musicTargVols[layer], musicVols[layer])
    alSourcef(musicSources[layer], AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicVols[layer] * musicFade)
    checkAudioErr("sourcef")

  if musicFade < 1.0:
    musicFade += dt
    musicFade = musicFade.clamp(0, 1)
    for layer in 0..<musicSources.len:
      alSourcef(musicSources[layer], AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicVols[layer] * musicFade)
      checkAudioErr("sourcef")

  var sourceState: ALint
  alGetSourcei(musicSources[0], AL_SOURCE_STATE, addr sourceState)
  checkAudioErr("getSourcei")

  let tmp = sfxQueue
  sfxQueue = @[]

  for q in tmp:
    play(q.sound, q.pos, q.pitch)
    echo $q

  if sourceState != AL_PLAYING:
    for idx in 0..<len musicSources:
      if not musicActive[idx]: continue
      if loopBuffers[idx] == 0: continue
      if songQueue.len > 0:
        let q = songQueue[0]
        songQueue.delete(0)
        q.song.play(skip = q.skip, inQueue = true)
      else:
        alSourcei(musicSources[idx], AL_BUFFER, Alint loopBuffers[idx])
        checkAudioErr("sourcei")
        alSourcei(musicSources[idx], AL_LOOPING, 1)
        checkAudioErr("sourcei")
        alSourcePlay(musicSources[idx])
        checkAudioErr("sourcePlay")
