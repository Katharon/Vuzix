import 'dart:convert';
import 'package:flutter/services.dart';
import 'ConfigParser.dart';
import '../models/Workflow.dart';

class ConfigFileReader {
  final ConfigParser _parser;

  ConfigFileReader({required ConfigParser parser}) : _parser = parser;

  /// Liest alle Workflows aus dem Verzeichnis.
  Future<List<Workflow>> readAllWorkflows(String directory) async {
    final List<Workflow> workflows = [];

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final configFiles = manifestMap.keys
        .where((path) => path.startsWith(directory) && path.endsWith('.xml'));

    for (final filePath in configFiles) {
      final parsedWorkflows = await _parser.parse(filePath);
      workflows.addAll(parsedWorkflows);
    }

    return workflows;
  }
}