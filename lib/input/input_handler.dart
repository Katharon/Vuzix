import 'dart:async';

import 'package:flutter/services.dart';

import 'device.dart';
import 'input_event.dart';
import 'input_translator.dart';
import '../ui/snackbar.dart';

class InputHandler {
  final InputTranslator translator;
  final CarouselItemsToShow itemsToShow;

  final _controller = StreamController<InputEvent>.broadcast();
  Stream<InputEvent> get keys => _controller.stream;
  void _stream(InputEvent event) {
    _controller.sink.add(event);
  }

  final Map<int, InputEvent> _lastKeys = {};

  InputHandler.fromDevice(Device device)
      : translator = device == Device.m4000
            ? M4000InputTranslator()
            : device == Device.blade
                ? BladeInputTranslator()
                : ConventionalInputTranslator(),
        itemsToShow = device == Device.blade
            ? CarouselItemsToShow.three
            : CarouselItemsToShow.five;

  bool onKey(KeyEvent event) {
    InputHandlingResult result = translator.onKey(event);

    if (result.event != null && event is KeyDownEvent) {
      print('onKey: ${event.logicalKey.keyLabel} -> ${result.event}');

      _lastKeys[DateTime.now().millisecondsSinceEpoch] = result.event!;
      _stream(result.event!);
    }

    if (result.event == InputEvent.twoFingersTap) {
      // special case for leaving the app
      var last3 = _lastKeys.entries.toList().reversed.take(3).toList();
      // three times twoFingersTap in under 1000ms
      if (last3.length == 3 &&
          last3[0].value == InputEvent.twoFingersTap &&
          last3[1].value == InputEvent.twoFingersTap &&
          last3[2].value == InputEvent.twoFingersTap &&
          last3[0].key - last3[2].key < 1000) {
        print('leaving app after 3 times twoFingersTap in under 1000ms');
        return false; // returning false means the event is not handled, so the last twoFingersTap will be passed on to the device which will escape the app
      } else if (event is KeyDownEvent &&
          last3[0].value == InputEvent.twoFingersTap &&
          last3[1].value != InputEvent.twoFingersTap) {
        // if this is the first twoFingersTap, show a snackbar to inform about the triple gesture
        showSnackBar("Tap both fingers three times to leave the app.");
      }
    }

    return result.handled;
  }
}
