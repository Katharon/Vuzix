import 'package:flutter/material.dart';
import 'package:flutter_vuzix/input/input_event.dart';

abstract class InputTranslator {
  final Map<String, InputEvent> keyMap;

  InputTranslator({required this.keyMap});

  InputHandlingResult onKey(KeyEvent event) {
    // per default we check with the label of the logical key
    String k = event.logicalKey.keyLabel;
    InputEvent? translatedEvent = keyMap[k];

    if (translatedEvent == InputEvent.twoFingersUp ||
        translatedEvent == InputEvent.twoFingersDown) {
      // special case for volume up and down, we want those to go to the operating system
      return InputHandlingResult(translatedEvent, handled: false);
    }

    // handled true means the operating system does not get the event
    return InputHandlingResult(translatedEvent);
  }
}

class InputHandlingResult {
  final bool handled;
  final InputEvent? event;

  InputHandlingResult(this.event, {this.handled = true});
}

/// mapping for web and windows
class ConventionalInputTranslator extends InputTranslator {
  ConventionalInputTranslator()
      : super(keyMap: {
          'Arrow Up': InputEvent.up,
          'Arrow Down': InputEvent.down,
          'Arrow Left': InputEvent.backward,
          'Arrow Right': InputEvent.forward,
          'Enter': InputEvent.tap,
          'Escape': InputEvent.twoFingersTap,
        });
}

/// mapping for Blade
class BladeInputTranslator extends InputTranslator {
  BladeInputTranslator()
      : super(keyMap: {
          'Arrow Up': InputEvent.up,
          'Arrow Down': InputEvent.down,
          'Arrow Left': InputEvent.backward,
          'Arrow Right': InputEvent.forward,
          'Audio Volume Up': InputEvent.twoFingersUp,
          'Audio Volume Down': InputEvent.twoFingersDown,
          'Backspace': InputEvent.twoFingersBackward,
          'Delete': InputEvent.twoFingersForward,
          'Enter': InputEvent.tap,
          'Go Back': InputEvent.twoFingersTap,
        });
}

/// mapping for M4000
class M4000InputTranslator extends InputTranslator {
  M4000InputTranslator()
      : super(keyMap: {
          'Arrow Up': InputEvent.up,
          'Arrow Down': InputEvent.down,
          'Arrow Left': InputEvent.backward,
          'Arrow Right': InputEvent.forward,
          'Audio Volume Up': InputEvent.twoFingersUp,
          'Audio Volume Down': InputEvent.twoFingersDown,
          'Backspace': InputEvent.twoFingersBackward,
          'Delete': InputEvent.twoFingersForward,
          'Select': InputEvent.tap,
          'Go Back': InputEvent.twoFingersTap,
          'Front Button': InputEvent.frontButton,
          'Middle Button': InputEvent.middleButton,
        });

  @override
  InputHandlingResult onKey(KeyEvent event) {
    // on M4000 we also have the three physical buttons
    // we can get the front and middle by checking the physical key debug name
    // we cannot distinguish the back button from the single tap (sadly)
    if (event.physicalKey.debugName == "Arrow Right") {
      return InputHandlingResult(InputEvent.frontButton);
    } else if (event.physicalKey.debugName == "Arrow Left") {
      return InputHandlingResult(InputEvent.middleButton);
    } else {
      // this accesses the mapping specified above:
      return super.onKey(event);
    }
  }
}
