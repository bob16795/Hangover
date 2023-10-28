import hangover/core/types/vector2
import hangover/core/types/point
import hangover/core/types/color
import hangover/core/types/rect
import hangover/core/types/font
import hangover/core/types/sfx
import hangover/ui/elements/uielement
import hangover/ui/types/uisprite
import hangover/core/logging
import hangover/core/audio

#TODO: comment
#TODO: add align

type
  UIButton* = ref object of UIElement
    ## A button element for ui
    font*: ptr Font
    fontMult*: float32
    action*: UIAction
    text*: string
    textUpdate*: UIUpdate
    hasTexture*: bool
    sprite*: Sprite
    toggleSprite*: Sprite
    hasSprite*: bool
    hasToggleSprite*: bool
    normalUI*, clickedUI*, disabledUI*, focusedUI*: UISprite
    iconScale*: float32
    toggle*: bool
    pressed*: bool
    color*: Color

var
  buttonHoverSound*: Sound
  buttonClickSound*: Sound

proc newUIButton*(texture: Texture, font: var Font, bounds: UIRectangle,
        action: UIAction = nil, text = "", disableProc: proc(): bool = nil,
        sprite: Sprite = Sprite(), toggleSprite: Sprite = Sprite(),
        toggle: bool = false): UIButton =
  ## creates a ui button
  result = UIButton()
  
  # generic element stuff 
  result.isActive = true
  result.bounds = bounds
  result.isDisabled = disableProc

  # set the font
  result.font = addr font

  # setup texture data
  if texture.isDefined():
    result.hasTexture = true
    result.normalUI = newUiSprite(texture, newRect(0, 0, 0.5, 1),
          newRect(0.125, 0.25, 0.125, 0.25)).scale(newVector2(64, 32))
    result.focusedUI = newUiSprite(texture, newRect(0.5, 0, 0.5, 1),
          newRect(0.625, 0.25, 0.125, 0.25)).scale(newVector2(64, 32))
    result.disabledUI = newUiSprite(texture, newRect(16, 0, 8, 8),
          newRect(18, 2, 4, 4))
  
  if sprite.texture != nil:
    result.sprite = sprite
    result.hasSprite = true
  if toggleSprite.texture != nil:
    result.toggleSprite = toggleSprite
    result.hasToggleSprite = true

  # setup the action
  if action != nil:
    result.action = action
  else:
    result.action = proc(i: int) = discard

  # setup the text and misc
  result.text = text
  result.toggle = toggle

method checkHover*(b: UIButton, parentRect: Rect, mousePos: Vector2) =
  ## updates the button element on a mouse move

  var wasFocused = b.focused

  # set focused to false
  b.focused = false

  # return if button is inactive
  if not b.isActive:
    return

  # return if the button is diabled
  if b.isDisabled != nil and b.isDisabled():
    return
  
  # get the bounds of the element
  var bounds = b.bounds.toRect(parentRect)

  # check if mouse is in the button
  if mousePos in bounds:
    if not wasFocused:
      if buttonHoverSound.valid:
        buttonHoverSound.play()
    b.focused = true

method click*(b: UIButton, button: int) =
  ## processes a click event for a button element
  
  # if the button is a toggle button toggle it
  if b.toggle:
    b.pressed = not b.pressed
    b.action(b.pressed.int)
  else:
    b.action(button)
  if buttonClickSound.valid:
    buttonClickSound.play()

method draw*(b: UIButton, parentRect: Rect) =
  ## draw a button element

  # return if the button isnt active
  if not b.isActive:
    return

  # get the bounds of the button
  var bounds = b.bounds.toRect(parentRect)

  # get the sprite and text color for the button
  var sprite = b.normalUI
  var textColor = newColor(0, 0, 0, 255)

  # check if the disabled func is defined
  if b.isDisabled != nil:
    # check if the button should be disabled
    if (b.isDisabled()):
      textColor = newColor(128, 0, 0, 255)
      sprite = b.disabledUI
    else:
      if b.focused:
        sprite = b.focusedUI
        textColor = newColor(0, 0, 0, 255)
  else:
    if b.focused:
      sprite = b.focusedUI
      textColor = newColor(0, 0, 0, 255)

  # if the button has a uiSprite draw it
  if b.hasTexture:
    sprite.draw(bounds)

  # if the button has a icon draw it
  if (b.hasSprite):
    let iconSize = bounds.height * b.iconScale
    let posx = bounds.x + ((bounds.width - iconSize) -
        sizeText(b.font[], b.text, b.fontMult * uiElemScale).x) / 2
    let posy = bounds.y + (bounds.height - iconSize) / 2
    b.sprite.draw(newVector2(posx, posy),
        0, newVector2(iconSize, iconSize), c = b.color)

  # if the button has a focused icon draw it
  if (b.hasToggleSprite):
    if b.pressed:
      var posx = (bounds.x) + ((bounds.width - bounds.height) -
          sizeText(b.font[], b.text, b.fontMult * uiElemScale).x) / 2
      b.toggleSprite.draw(newVector2(posx, bounds.y),
          0, newVector2(bounds.height, bounds.height), c = b.color)
    if b.focused:
      var posx = (bounds.x) + ((bounds.width - bounds.height) -
          sizeText(b.font[], b.text, b.fontMult * uiElemScale).x) / 2
      b.toggleSprite.draw(newVector2(posx, bounds.y),
          0, newVector2(bounds.height, bounds.height), c = newColor(255,
              255, 255, 128))

  # draw the buttons text centered
  if (b.text != ""):
    var posx: float32 = (bounds.x + ((
                bounds.width - sizeText(b.font[],
                b.text, b.fontMult * uiElemScale).x) / 2))
    var posy: float32 = bounds.y + ((bounds.height - b.font[].sizeText(b.text, b.fontMult * uiElemScale).y.float32) / 2)
    if b.hasSprite:
      posx = (bounds.x + bounds.height + 10) + ((bounds.width - bounds.height) -
          sizeText(b.font[], b.text, b.fontMult * uiElemScale).x) / 2
    b.font[].draw(b.text, newPoint(posx.cint, posy.cint), textColor, b.fontMult * uiElemScale)

method update*(b: UIButton, parentRect: Rect, mousePos: Vector2,
    dt: float32) =
  ## processes a frame for the button

  # return if the button is not active
  if not b.isActive:
    return

  # update the button text
  if b.textUpdate != nil:
    b.text = b.textUpdate()
  if b.fontMult == 0:
    b.fontMult = 1
  if b.iconScale == 0:
    b.iconScale = 0.75
