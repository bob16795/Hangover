import types/sfx
import types/song
import types/vector2
import random
import openal
import hangover/core/logging
import std/enumerate
import options

const
  SOURCES = 30
  MUSIC_QUEUE_LENGTH = 3
  MUSIC_SAMPLE_RATE = 44100
  MUSIC_BLOCK_LENGTH = 4096

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

  MusicSource* = object
    source: ALuint
    buffers: array[MUSIC_QUEUE_LENGTH, ALuint]
    bufferIndex: int
    targetVolume, volume: float32
    targetMuffle, muffle: float32
    lastSample: int16
    active: bool

var
  device: ALCdevice
  audioCtx: ALCcontext
  
  # music
  playingSong: Song
  playingOffset: int
  fadingSong: Song
  fadingOffset: int 
  fadingVolume: float32
  songQueue: seq[SongQueueEntry]
  musicSources: array[MAX_SONG_LAYERS, MusicSource]
  musicFade: float32

  # sfx
  soundSources: array[SOURCES, ALuint]
  nextSoundSource: uint = 0

  alPaused: bool
  framePlayed: seq[Sound]

  audioSize*: Vector2 = newVector2(1.0, 1.0)

  volume: array[VolumeEntry, float32]

  stereo: bool

proc checkAudioErr*(name: string) {.inline.} =
  let e = algetError()
  if e != AL_NO_ERROR:
    LOG_INFO "ho->audio", "openal error", e, "in", name

proc initMusicSource*(): MusicSource =
  alGenSources(ALsizei 1, addr result.source)
  alGenBuffers(ALsizei MUSIC_QUEUE_LENGTH, addr result.buffers[0])
  result.targetVolume = 1.0
  result.volume = 1.0

proc initAudio*() =
  ## sets up the audio system
  device = alcOpenDevice(nil)

  if device == nil:
    LOG_ERROR "ho->audio", "Failed to get default audio device"
    return

  audioCtx = device.alcCreateContext(nil)

  if audioCtx == nil:
    LOG_ERROR "ho->audio", "Failed to make audio context"
    return

  if not alcMakeContextCurrent(audioCtx):
    LOG_ERROR "ho->audio", "Failed to use audio context"
    return

  # generate song source
  for source in musicSources.mitems():
    source = initMusicSource()

  # geenrate sound sources
  alGenSources(ALsizei SOURCES, addr soundSources[0])

  # set default music data
  for v in VolumeEntry.low..VolumeEntry.high:
    volume[v] = 1.0
  
  audioInit = true

proc setStereo*(value: bool) =
  if not audioInit: return

  stereo = value

proc pauseAudio*() =
  if not audioInit: return

  if alPaused: return
  for musicSource in musicSources:
    alSourcePause(musicSource.source)
    checkAudioErr("sourcePause (pauseAudio)")

  alPaused = true

proc playAudio*() =
  if not audioInit: return

  if not alPaused: return
  for musicSource in musicSources:
    alSourcePlay(musicSource.source)
    checkAudioErr("sourcePlay (playAudio)")
  alPaused = false

proc setLayerMuffle*(layer: int, muffle: float32) =
  if not audioInit: return

  musicSources[layer].targetMuffle = muffle

proc setVolume*(vol: float32, kind: VolumeEntry) =
  if not audioInit: return

  volume[kind] = vol.clamp(0, 1)

  case kind:
  of volMusic:
    for layer in 0 ..< musicSources.len:
      alSourcef(musicSources[layer].source, AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicSources[layer].volume * musicFade)
      checkAudioErr("alSourcef (gain setVol)")
  of volMaster:
    for layer in 0 ..< musicSources.len:
      alSourcef(musicSources[layer].source, AL_GAIN, ALfloat volume[volMaster] * volume[volMusic] * musicSources[layer].volume * musicFade)
      checkAudioErr("alSourcef (gain setVol)")
    for s in soundSources:
      alSourcef(s, AL_GAIN, ALfloat volume[volMaster] * volume[volSfx])
      checkAudioErr("alSourcef (gain setVol)")
  of volSfx:
    for s in soundSources:
      alSourcef(s, AL_GAIN, ALfloat volume[volMaster] * volume[volSfx])
      checkAudioErr("alSourcef (gain setVol)")

# proc getSongLooping*(): bool =
#   # gets how many songs are queued
#   var looping: ALint
#   alGetSourcei(musicSources[0].source, AL_LOOPING, addr looping)
#   checkAudioErr("getSourceI (loop, getSongLooping)")
# 
#   return looping != 0

  
proc getSongQueueSize*(): int =
  ## gets how many songs are queued
  if not audioInit: return

  result = songQueue.len

var
  playingGlitchOffset: int
  fadingGlitchOffset: int

proc glitchAudio*(save: bool = false) =
  if not audioInit: return

  if not save:
    playingOffset = playingGlitchOffset
    fadingOffset = fadingGlitchOffset

  playingGlitchOffset = playingOffset
  fadingGlitchOffset = fadingOffset

proc play*(
  song: Song,
  fade: bool = false,
  force: bool = false,
  skip: bool = false,
  inQueue: bool = false,
) =
  ## plays a song
  
  if not audioInit: return
  if playingSong == song: return

  var playing: ALint
  alGetSourcei(musicSources[0].source, AL_SOURCE_STATE, addr playing)
  checkAudioErr("getSorucei")
  let
    looping = playingOffset >= playingSong.loop
  if not inQueue and not force and skip and not looping and playing == AL_PLAYING:
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
    musicSources[idx].active = false
    if song.layers[idx].isNone():
      musicSources[idx].targetVolume = 0.0
      continue
    musicSources[idx].targetVolume = if idx == 0: 1.0 else: 0.0
    musicSources[idx].active = true
  
  fadingSong = playingSong
  fadingOffset = playingOffset

  playingSong = song
  playingOffset = 0

  if skip:
    playingOffset = fadingOffset - fadingSong.loop

proc setLayerVolume*(layer: range[0..MAX_SONG_LAYERS-1], vol: float32, force: bool = false) =
  if not audioInit: return

  if not musicSources[layer].active: return
  musicSources[layer].targetVolume = vol
  if force:
    musicSources[layer].volume = vol
    alSourcef(
      musicSources[layer].source,
      AL_GAIN,
      ALfloat volume[volMaster] * volume[volMusic] * musicSources[layer].volume * musicFade
    )
    checkAudioErr("sourcef")

proc setMusicSpeed*(speed: float32) =
  if not audioInit: return

  for m in musicSources:
    alSourcef(m.source, AL_PITCH, speed)
    checkAudioErr("sourcef")

proc getMusicOffset*(): int =
  if not audioInit: return

  playingOffset - playingSong.loop

proc play*(sound: Sound, pos: Vector2 = newVector2(0, 0),
    pitch: float32 = 1.0) =
  ## plays a sound, pos is for spacial sound
  if not audioInit: return

  if sound == nil: return

  if sound in framePlayed: return

  framePlayed &= sound
  var sourceState: ALint
  nextSoundSource += 1

  let source = soundSources[nextSoundSource mod SOURCES]

  alGetSourcei(source, AL_SOURCE_STATE, addr sourceState)
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
  if not audioInit: return

  framePlayed = @[]
  if alPaused: return
  playingOffset = max(0, playingOffset)

  # volume
  for source in musicSources.mitems():
    if source.targetVolume < source.volume:
      source.volume -= dt * 0.5
      source.volume = max(source.targetVolume, source.volume)
    if source.targetVolume > source.volume:
      source.volume += dt * 0.5
      source.volume = min(source.targetVolume, source.volume)
    alSourcef(
      source.source,
      AL_GAIN,
      ALfloat volume[volMaster] * volume[volMusic] * source.volume * musicFade
    )
    checkAudioErr("sourcef")
    
    if source.targetMuffle < source.muffle:
      source.muffle -= dt * 1.0
      source.muffle = max(source.targetMuffle, source.muffle)
    if source.targetMuffle > source.muffle:
      source.muffle += dt * 1.0
      source.muffle = min(source.targetMuffle, source.muffle)

  if musicFade < 1.0:
    musicFade += dt
    musicFade = musicFade.clamp(0, 1)
    for source in musicSources.mitems():
      alSourcef(
        source.source,
        AL_GAIN,
        ALfloat volume[volMaster] * volume[volMusic] * source.volume * musicFade
      )
      checkAudioErr("sourcef")

  # queue
  let
    looping = playingOffset >= playingSong.loop

  if songQueue.len > 0 and looping:
    let q = songQueue[0]
    songQueue.delete(0)
    q.song.play(skip = q.skip, inQueue = true)

  var
    processed: ALint
    queued: ALint
    tempBuffer: array[MUSIC_BLOCK_LENGTH, int16]
    startOffset = playingOffset

  for layer, source in enumerate(musicSources.mitems()):
    alSourcePause(source.source)
    checkAudioErr("sourcepause")

    if playingSong.layers[layer].isNone:
      continue
    
    playingOffset = startOffset

    alGetSourceI(source.source, AL_BUFFERS_PROCESSED, addr processed) 
    checkAudioErr("sourcei")
    alGetSourceI(source.source, AL_BUFFERS_QUEUED, addr queued) 
    checkAudioErr("sourcei")

    let
      toUpdate = min(MUSIC_QUEUE_LENGTH - 1, processed + (MUSIC_QUEUE_LENGTH - queued - 1))
  
    # This code is HOT, so please optimize
    # I know its safe... (sorry future me)
    {.push checks: off.}

    for _ in 0..toUpdate:
      let
        bufferIndex = source.bufferIndex mod MUSIC_QUEUE_LENGTH
        buffer = source.buffers[bufferIndex]
      
      if queued != 0:
        alSourceUnqueueBuffers(source.source, 1, addr buffer)
        checkAudioErr("sourceunqueuebuffers")


      for tempIdx in 0..<len tempBuffer:
        if playingSong.baseLen == 0:
          tempBuffer[tempIdx] = 0
        else:
          let
            sampleIdx = if playingOffset < playingSong.loop: playingOffset
                        else: playingSong.loop + ((playingOffset - playingSong.loop) mod (playingSong.baseLen - playingSong.loop))
            sample = playingSong.layers[layer].get().data[sampleIdx]

          let
            newSample = clamp(
              sample.float32 * (1.0 - source.muffle) + source.lastSample.float32 * source.muffle, 
              int16.low.float32, int16.high.float32,
            ).int16
          tempBuffer[tempIdx] = newSample
        
        source.lastSample = tempBuffer[tempIdx]

        playingOffset += 1

      alBufferData(
        buffer, AL_FORMAT_STEREO16,
        addr tempBuffer, ALSizei sizeof(int16) * tempBuffer.len,
        MUSIC_SAMPLE_RATE
      )
      checkAudioErr("bufferdata")
      if queued != 0:
        alSourceQueueBuffers(source.source, 1, addr buffer)
        checkAudioErr("sourcequeuebuffers")
      source.bufferIndex += 1
    
    if queued == 0:
      alSourceQueueBuffers(source.source, MUSIC_QUEUE_LENGTH, addr source.buffers[0])
      checkAudioErr("sourcequeuebuffers")

    {.pop.}

    alSourcePlay(source.source)
    checkAudioErr("sourceplay")
  playingOffset = if playingSong.baseLen == 0: 0
                  elif playingOffset < playingSong.loop: playingOffset
                  else: playingSong.loop + ((playingOffset - playingSong.loop) mod (playingSong.baseLen - playingSong.loop))
