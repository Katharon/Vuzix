import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef OnSpeech = void Function(String text);

class STT {
  /* -------- Singleton -------- */
  STT._();
  static final STT instance = STT._();

  /* -------- Intern ----------- */
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  late OnSpeech _callback;

  // Restart-Konfig
  late String _localeId;
  late Duration _listenFor;
  late Duration _pauseFor;

  /* -------- Public ----------- */
  Future<void> init({
    required OnSpeech onSpeech,
    String localeId = 'de-DE',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor  = const Duration(seconds: 3),
  }) async {
    if (_ready) return;                       // schon initialisiert

    _callback  = onSpeech;
    _localeId  = localeId;
    _listenFor = listenFor;
    _pauseFor  = pauseFor;

    _ready = await _speech.initialize(
      onStatus: _statusListener,
      onError : (e) => debugPrint('[STT] Fehler: $e'),
      debugLogging: true,
    );

    if (_ready) _startListening();
  }

  Future<void> dispose() async {
    if (!_ready) return;
    await _speech.stop();
    _ready = false;
  }

  /* -------- Helpers ---------- */
  void _startListening() {
    if (_speech.isListening) return;          // busy-Guard

    final opts = stt.SpeechListenOptions(
      onDevice        : false,                 // offline → kein error_network
      partialResults  : true,
      cancelOnError   : true,
      autoPunctuation : true,
    );

    _speech.listen(
      localeId      : _localeId,
      listenFor     : _listenFor,
      pauseFor      : _pauseFor,
      listenOptions : opts,
      onResult: (r) {
        final txt = r.recognizedWords.toLowerCase().trim();
        if (txt.isNotEmpty) _callback(txt);
      },
    );
  }

  void _statusListener(String status) async {
    // Wenn Engine stoppt → nach kurzer Pause neu starten
    if (_ready && (status == 'notListening' || status == 'done')) {
      await Future.delayed(const Duration(milliseconds: 500));
      _startListening();
    }
  }
}
