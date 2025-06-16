enum InputEvent {
  /// one finger up
  up,

  /// one finger down
  down,

  /// one finger backward
  backward,

  /// one finger forward
  forward,

  /// one finger tap or M4000 back button (we cannot distinguish)
  tap,

  /// two fingers tap = Vuzix standard back button
  twoFingersTap,

  /// two fingers up = Vuzix standard volume up
  twoFingersUp,

  /// two fingers down = Vuzix standard volume down
  twoFingersDown,

  /// two fingers backward
  twoFingersBackward,

  /// two fingers forward
  twoFingersForward,

  /// M4000 front button (in standard used like right button)
  frontButton,

  /// M4000 middle button (in standard used like left button)
  middleButton
}
