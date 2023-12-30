import hangover/core/types/Texture
import hangover/core/types/Vector2
import hangover/core/types/Color
import hangover/core/types/Rect
import random
import math

#TODO: comment
#TODO: add scale

template ifor*(variable: untyped, list: untyped, body: untyped): untyped =
  for i in 0..<list.len:
    template variable(): untyped = list[i]
    body

const
  MAX_PARTICLES: uint = 1000

var
  reducedParticles*: bool = false

proc maxParticles(): uint =
  if reducedParticles:
    return (MAX_PARTICLES.float * 0.5).uint
  else:
    return MAX_PARTICLES

type
  ParticleProps* = object
    ## particle properties
    position*, positionVariation*: Vector2
    velocity*, velocityVariation*: Vector2

    startColor*, endColor*: Color

    startSize*, endSize*: float

    lifeTime*: float
    lifeTimeVariation*: float

  ParticleSystem* = object
    ## a particle system, stores up to the max particles
    pool: array[MAX_PARTICLES, Particle]
    idx: uint
    texture*: Texture

  Particle = object
    position*: Vector2
    velocity*: Vector2

    startColor*, endColor*: Color

    startSize*, endSize*: float

    lifeTime*: float
    lifeRemaining*: float

    isActive*: bool

proc clear*(ps: var ParticleSystem) =
  ifor part, ps.pool:
    part.isActive = false

proc update*(ps: var ParticleSystem, dt: float32) =
  ## updates a particle system
  ifor part, ps.pool:
    if not part.isActive:
      continue
    if part.lifeRemaining <= 0:
      part.isActive = false
      continue
    part.lifeRemaining -= dt
    part.position = part.position + part.velocity * dt

proc draw*(ps: ParticleSystem, offset: Vector2) =
  ## draws a particle system
  template lerp(a, b: untyped, pc: float): untyped =
    b.float + (a.float - b.float) * pc

  for p in ps.pool:
    if not p.isActive:
      continue
    let
      pc = clamp(p.lifeRemaining / p.lifeTime, 0.0, 1.0)
      c = newColor(lerp(p.startColor.r, p.endColor.r, pc).uint8,
                   lerp(p.startColor.g, p.endColor.g, pc).uint8,
                   lerp(p.startColor.b, p.endColor.b, pc).uint8,
                   lerp(p.startColor.a, p.endColor.a, pc).uint8)
      s = lerp(p.startSize, p.endSize, pc)
      hitbox = newRect((p.position - offset -
                             newVector2(s / 2, s / 2)),
                             newVector2(s, s))
    ps.texture.draw(newRect(0, 0, 1, 1), hitbox, color = c)

proc randVector*(size: float32): Vector2 {.inline.} =
  result = newVector2(0, sqrt(rand(0.float32..size.float32 * size.float32)))
  result.angle = rand(0.float32..(2 * PI).float32)

proc emit*(ps: var ParticleSystem, props: ParticleProps) =
  ## creates a new particle
  var p = Particle()
  ps.idx += 1

  if reducedParticles:
    if ps.idx mod 2 == 0: return

  p.isActive = true
  p.position = props.position
  if props.positionVariation != newVector2(0, 0):
    let pos = randVector(props.positionVariation.x)
    p.position += pos

  p.velocity = props.velocity
  if props.velocityVariation != newVector2(0, 0):
    let pos = randVector(props.velocityVariation.x)
    p.velocity += pos

  p.startColor = props.startColor
  p.endColor = props.endColor

  p.lifeTime = props.lifeTime
  p.lifeTime += rand(-props.lifeTimeVariation..props.lifeTimeVariation)
  p.lifeRemaining = p.lifeTime

  p.startSize = props.startSize
  p.endSize = props.endSize

  ps.pool[ps.idx mod maxParticles()] = p

proc tryEmit*(ps: var ParticleSystem, props: ParticleProps) =
  ## emits a particle if the next particle is free
  if not ps.pool[(ps.idx + 1) mod MAX_PARTICLES].isActive:
    ps.emit(props)
