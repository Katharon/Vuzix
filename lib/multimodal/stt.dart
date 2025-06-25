import 'dart:async';
import 'package:flutter/services.dart';

class STT {
  STT._();
  static final STT instance = STT._();

  final _cmd = const MethodChannel('vuzix/speech');
  final _evt = const EventChannel('vuzix/speech/events');

  final _cmdCtrl = StreamController<String>.broadcast();
  final _recCtrl = StreamController<String>.broadcast();

  Future<void> init({List<String> initialPhrases = const []}) async {
    if (initialPhrases.isNotEmpty) {
      await addPhrases(initialPhrases);
    }
    _evt.receiveBroadcastStream().listen((dynamic p) {
      final phrase = p.toString().toLowerCase();
      _cmdCtrl.add(phrase);
      _recCtrl.add(phrase); // für Dictation-Log
    });
  }

  Future<void> addPhrases(List<String> words) =>
      _cmd.invokeMethod('registerPhrases', words);

  /// Start/Stop Dictation-Stream (falls benötigt)
  Future<void> startDictation() => _cmd.invokeMethod('startDictation');
  Future<void> stopDictation()  => _cmd.invokeMethod('stopDictation');

  /// ---------- High-Level-API ----------
  Stream<bool> listenFor(String word) =>
      _cmdCtrl.stream.map((p) => p == word.toLowerCase());

  Stream<String> record() => _recCtrl.stream;
}
