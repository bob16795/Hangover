import core/types/sound
import core/types/vector2
import rendering/sprite
import rectcomponent
import ecs/component
import core/templates
import ecs/genmacros

component SoundComponent:
  var
    sound: Sound

  proc playSound() =
    var rect = parent[RectComponentData]
    this.sound.play(rect.position)

  proc construct(soundFile: string) =
    this.sound = newSound(soundFile)
