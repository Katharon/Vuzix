import 'package:flutter/services.dart' show rootBundle;

class XmlManager {
  /// Liest eine Asset-Datei als String.
  Future<String> read(String path) async => rootBundle.loadString(path);
}