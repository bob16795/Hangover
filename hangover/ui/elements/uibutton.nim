import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/types/sfx
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/ui/types/uifield
import hangover/core/logging
import hangover/core/audio
import options

#TODO: comment
#TODO: add align

type
  UIButton* = ref object of UIElement
    ## A button element for ui
    font*: Font
    font_scale_mult*: float32
    action*: UIAction
    text*: UIField[string]

    icon*: Sprite
    icon_toggle*: Sprite
    icon_scale*: float32

    normal_sprite*: UISprite
    clicked_sprite*: UISprite
    disabled_sprite*: UISprite
    focused_sprite*: UISprite

    toggle*: bool
    pressed*: bool
    color*: UIField[Color]
    text_color*: UIField[Color]

var
  buttonHoverSound*: Sound
  buttonClickSound*: Sound
  buttonFailSound*: Sound

method checkHover*(b: UIButton, parentRect: Rect, mousePos: Vector2) =
  ## updates the button element on a mouse move

  let wasFocused = b.focused

  # set focused to false
  b.focused = false

  # return if button is inactive
  if not b.isActive:
    return

  # get the bounds of the element
  let bounds = b.bounds.toRect(parentRect)

  # check if mouse is in the button
  if mousePos in bounds:
    if not wasFocused:
      buttonHoverSound.play()
    b.focused = true

method click*(b: UIButton, button: int, key: bool) =
  ## processes a click event for a button element
  if not b.focused:
    return

  # if the button is a toggle button toggle it
  if not b.disabled.value:
    if b.toggle:
      b.pressed = not b.pressed
      b.action(b.pressed.int)
    else:
      b.action(button)
    buttonClickSound.play()
  else:
    if b.color.value.a == 0:
      return
    buttonFailSound.play()

method draw*(b: UIButton, parentRect: Rect) =
  ## draw a button element

  # return if the button isnt active
  if not b.isActive:
    return

  # get the bounds of the button
  let bounds = b.bounds.toRect(parentRect)

  # get the sprite and text color for the button
  var
    sprite = b.normal_sprite
    color = b.color.value
    text_color = b.text_color.value.withAlpha(color.a)

  # check if the disabled func is defined
  # check if the button should be disabled
  if b.disabled.value:
    if b.disabled_sprite != nil:
      sprite = b.disabled_sprite
    if color.a == 0:
      return
  else:
    if b.focused and b.focused_sprite != nil:
      sprite = b.focused_sprite

  var contrast = false

  # if the button has a uiSprite draw it
  if sprite != nil:
    sprite.draw(bounds, color = color, contrast = ContrastEntry(mode: if contrast: fg else: bg))
    contrast = not contrast

  let
    text = b.text.value

    base_text_size = b.font.sizeText(text)
    max_scale = bounds.width / base_text_size.x * 0.9
    text_scale = min(b.font_scale_mult * uiElemScale, max_scale)
    text_size = base_text_size * text_scale

  # draw the buttons text centered
  if text != "":
    let
      offset = if b.icon != nil: bounds.height + 10 else: 0

      text_pos = newVector2(
        bounds.x + offset + (bounds.width - offset - text_size.x) / 2,
        bounds.y + (bounds.height - text_size.y) / 2,
      )

    b.font.draw(text, text_pos, text_color, text_scale, contrast = ContrastEntry(mode: if contrast: fg else: bg))

  # if the button has a icon draw it
  if b.icon != nil:
    let
      icon_size = bounds.height * b.icon_scale
      icon_pos = newVector2(
        bounds.x + ((bounds.width - icon_size) - text_size.x) / 2,
        bounds.y + (bounds.height - icon_size) / 2,
      )

    b.icon.draw(
      icon_pos,
      0,
      newVector2(icon_size),
      color = color,
      contrast = ContrastEntry(mode: if contrast: fg else: bg),
    )

  if b.icon != nil:
    contrast = not contrast

  # if the button has a focused icon draw it
  if b.icon_toggle != nil:
    let
      icon_pos = newVector2(
        bounds.x + (bounds.width - bounds.height - text_size.x) / 2,
        bounds.y,
      )

    if not b.toggle:
      if b.focused:
        b.icon_toggle.draw(
          icon_pos,
          0,
          newVector2(bounds.height),
          color = newColor(255, 255, 255, 255),
          contrast = ContrastEntry(mode: if contrast: fg else: bg),
        )
    else:
      if b.pressed:
        b.icon_toggle.draw(
          icon_pos,
          0,
          newVector2(bounds.height),
          color = color,
          contrast = ContrastEntry(mode: if contrast: fg else: bg),
        )
      if b.focused:
        b.icon_toggle.draw(
          icon_pos,
          0,
          newVector2(bounds.height),
          color = newColor(255, 255, 255, 128),
          contrast = ContrastEntry(mode: if contrast: fg else: bg),
        )

method update*(b: UIButton, parentRect: Rect, mousePos: Vector2,
    dt: float32, active: bool) =
  ## processes a frame for the button

  # update the button text
  if b.font_scale_mult == 0:
    b.font_scale_mult = 1.0
  if b.icon_scale == 0:
    b.icon_scale = 1.0

method focusable*(b: UIButton): bool =
  ## returns true if you can focus the element
  if b.color.value.a == 0:
    return false
  return not b.neverFocus
