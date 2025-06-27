import openal
import streams
import options
import ../lib/readwav
import ../lib/vorbis
import hangover/core/logging
import async

# TODO: comment
const MAX_SONG_LAYERS* = 5

type
  SongLayer* = object
    data*: seq[int16]

  Song* = object
    layers*: array[MAX_SONG_LAYERS, Option[SongLayer]]
    baseLen*: int
    loop*: int

template `+`(p: pointer, off: int): pointer =
  cast[pointer](cast[ByteAddress](p) +% off * sizeof(uint8))

proc newSongMem*(s: Stream, loopPoint: float32 = 0, ogg = false): Song =
  let wav = if ogg:
              loadVorbis(s.readAll())
            else:
              readWav(s)
  s.close()

  var baseLayer: SongLayer

  baseLayer.data = newSeq[int16](int(wav.size / sizeof(int16)))
  copyMem(addr baseLayer.data[0], wav.data, wav.size)

  result.layers[0] = some(baseLayer)
  result.baseLen = (wav.size / sizeof(int16)).int
  result.loop = ((result.baseLen.float32 / wav.channels.float32) * clamp(loopPoint, 0.0, 1.0)).int * wav.channels

proc addLayer*(song: var Song, s: Stream, idx: range[0..MAX_SONG_LAYERS - 1], ogg = false) =
  let wav = if ogg:
              loadVorbis(s.readAll())
            else:
              readWav(s)
  s.close()

  var baseLayer: SongLayer

  if wav.size != song.baseLen:
    LOG_WARN "ho->song", "Incorrectly sized layer for song"

    # return
  
  baseLayer.data = newSeq[int16](int(wav.size / sizeof(int16)))
  copyMem(addr baseLayer.data[0], wav.data, wav.size)

  song.layers[idx] = some(baseLayer)

proc newSong*(file: string, loopPoint: float32 = 0, ogg = false): Song =
  let s = newFileStream(file)
  result = newSongMem(s, loopPoint, ogg)
