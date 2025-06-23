import 'package:flutter_tts/flutter_tts.dart';

FlutterTts flutterTts = FlutterTts();

Future speak(String text) async {
  await flutterTts.setLanguage("de-AT");
  await flutterTts.setPitch(1.0);
  await flutterTts.speak(text);
}
