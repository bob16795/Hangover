import hangover/core/types/rect
import hangover/core/types/vector2
import math
import tables
import algorithm
import segfaults

type
  CollisionLayer* = distinct uint8
  CollisionRect* = ref object of Rect
    dynamic*: bool
    velocity*: Vector2
    elasticity*: float
  
  CollisionData = object
    collision: bool
    dist: float32
    exit: float32
    norm: Vector2
    rect: CollisionRect

  CollisionCallback* = proc(a, b: var CollisionRect)

  CollisionManager* = object
    collisions: Table[CollisionLayer, seq[CollisionRect]]
    interactions: Table[CollisionLayer, set[CollisionLayer]]
    callbacks: Table[array[2, CollisionLayer], CollisionCallback]

proc `+`(a, b: CollisionLayer): CollisionLayer {.borrow.}
proc `==`(a, b: CollisionLayer): bool {.borrow.}

var
  collisionSteps*: int = 5
  lastCollisionLayerId {.compileTime.}: CollisionLayer

template newCollisionLayer*(name: untyped): untyped =
  ## creates a collision layer
  const name = static: lastCollisionLayerId
  export name

  static:
    lastCollisionLayerId = lastCollisionLayerId + 1.CollisionLayer

func rayVsRect(start: Vector2, dir: Vector2, target: Rect): tuple[
    success: bool, contact_normal, contact_point: Vector2, contact_time: float32,
    exit_time: float32] {.inline.} =
  var
    t_near_x = (target.x.float32 - start.x) / dir.x
    t_near_y = (target.y.float32 - start.y) / dir.y

    t_far_x = (target.x.float32 + target.width.float32 - start.x) / dir.x
    t_far_y = (target.y.float32 + target.height.float32 - start.y) / dir.y

  if dir.x == 0 and abs(target.x.float32 + target.width.float32 - start.x) <= 0:
    t_near_x = 0
    t_far_x = 0

  if dir.y == 0 and abs(target.y.float32 + target.height.float32 - start.y) <= 0:
    t_near_y = 0
    t_far_y = 0

  if t_near_x > t_far_x: swap(t_near_x, t_far_x)
  if t_near_y > t_far_y: swap(t_near_y, t_far_y)

  if (t_near_x > t_far_y or t_near_y > t_far_x):
    return (success: false, contact_normal: Vector2(), contact_point: Vector2(),
        contact_time: 0'f32, exit_time: 0'f32)

  let t_hit_near = max(t_near_x, t_near_y)
  let t_hit_far = min(t_far_x, t_far_y)

  if (t_hit_far < 0):
    return (success: false, contact_normal: Vector2(), contact_point: Vector2(),
        contact_time: 0'f32, exit_time: 0'f32)

  let
    contact_point = start + (dir * t_hit_near.float32)
  var
    contact_normal: Vector2

  if (t_near_x > t_near_y):
    if dir.x < 0: contact_normal = newVector2(1, 0)
    else: contact_normal = newVector2(-1, 0)
  elif (t_near_x < t_near_y):
    if dir.y < 0: contact_normal = newVector2(0, 1)
    else: contact_normal = newVector2(0, -1)

  return (success: true, contact_normal: contact_normal,
      contact_point: contact_point, contact_time: t_hit_near,
      exit_time: t_hit_far)

func dynamicRectVsRect(dynamicRect: CollisionRect, staticRect: CollisionRect, elapsed: float32): CollisionData {.inline.} =
  if dynamicRect.velocity == Vector2():
    return

  let
    halfSize = newVector2((dynamicRect.width / 2), (dynamicRect.height / 2))
    tmpStatic = newRect((staticRect.x - halfSize.x),
                        (staticRect.y - halfSize.y),
                        staticRect.width + dynamicRect.width,
                        staticRect.height + dynamicRect.height)
    r = rayVsRect(dynamicRect[].location + halfSize, dynamicRect.velocity * elapsed, tmpStatic)

  if r.success and r.contact_time >= 0.0 and r.contact_time <= 1:
    result.collision = true
    result.rect = staticRect
    result.norm = r.contact_normal
    result.dist = r.contact_time
    result.exit = r.exit_time

func resolveCollision(startVelocity, velocity: Vector2, a, b: CollisionRect, elapsed: float32): Vector2 {.inline.} =
  if a.dynamic != b.dynamic:
    var dRect, sRect: CollisionRect
    if a.dynamic:
      dRect = a
      sRect = b
    else:
      dRect = b
      sRect = a
    var r = dynamicRectVsRect(dRect, sRect, elapsed)
    if r.collision:
      var norm = newVector2(r.norm.x * abs(velocity.x), r.norm.y * abs(velocity.y)) * (1 - r.dist)
      var targetVel = velocity + norm
      var elastic = newVector2(-targetVel.x * abs(r.norm.x), -targetVel.y * abs(r.norm.y)) + (newVector2(velocity.x * abs(r.norm.x), velocity.y * abs(r.norm.y)) * -1) * dRect.elasticity
      return norm + elastic

proc newCollisionRect*(x, y, w, h: float32, v: bool): CollisionRect =
  result = CollisionRect()
  result.x = x
  result.y = y
  result.width = w
  result.height = h
  
  result.dynamic = v

proc newCollisionRect*(location, size: Vector2, v: bool): CollisionRect =
  result = newCollisionRect(location.x, location.y, size.x, size.y, v)

proc newCollisionRect*(rect: Rect, v: bool): CollisionRect =
  result = newCollisionRect(rect.location, rect.size, v)

proc setCollides*(cm: var CollisionManager, layer: CollisionLayer, collides: set[CollisionLayer]) =
  cm.interactions[layer] = collides

proc clear*(cm: var CollisionManager) =
  for layerKey in cm.collisions.keys:
    cm.collisions[layerkey] = @[]

proc clearLayer*(cm: var CollisionManager, layer: CollisionLayer) =
  if layer in cm.collisions:
    cm.collisions[layer] = @[]

proc register*(cm: var CollisionManager, add: seq[CollisionRect], layer: CollisionLayer) =
  if layer in cm.collisions:
    cm.collisions[layer] &= add
  else:
    cm.collisions[layer] = add

proc register*(cm: var CollisionManager, add: CollisionRect, layer: CollisionLayer) =
  if layer in cm.collisions:
    cm.collisions[layer] &= add
  else:
    cm.collisions[layer] = @[add]

proc quickCmp(a, b: CollisionData): int = cmp(a.dist, b.dist)

proc updateStep*(cm: var CollisionManager, dt: float32) =
  for layerKey in cm.collisions.keys:
    for interactKey in cm.interactions[layerKey]:
      if not(interactKey in cm.collisions): continue
      for collisionAi in 0..<len cm.collisions[layerKey]:
        template collisionA: untyped = cm.collisions[layerKey][collisionAi]
        if collisionA.dynamic != true: continue
        var resolutions: seq[CollisionData]
        var checkRect: Rect
        checkRect.location = collisionA[].location - 2 * collisionA[].size
        checkRect.size = 3 * collisionA[].size + (dt * collisionA.velocity)

        for collisionBi in 0..<len cm.collisions[interactKey]:
          template collisionB: untyped = cm.collisions[interactKey][collisionBi]
          if collisionB.dynamic != false: continue
          if not(collisionB[] in checkRect): continue

          let resolution = dynamicRectVsRect(
            collisionA,
            collisionB,
            dt
          )

          if resolution.collision:
            resolutions &= resolution
            try:
              cm.callbacks[[layerKey, interactKey]](collisionA, collisionB)
            except:
              discard

        resolutions.sort(quickCmp)

        var startVel = collisionA.velocity
        for resolution in resolutions:
          collisionA.velocity += resolveCollision(startVel, collisionA.velocity, collisionA, resolution.rect, dt)
          if collisionA.velocity == newVector2(0, 0): break

        collisionA[].location = collisionA[].location + collisionA.velocity * dt

proc update*(cm: var CollisionManager, dt: float32) =
  var stepDt = dt / collisionSteps.float32
  for s in 0..<collisionSteps:
    cm.updateStep(stepDt)
