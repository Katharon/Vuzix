import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';

class StepLogEntry {
  final String title;
  final DateTime start;
  DateTime? end;
  String? note;
  String? imagePath;
  String? stepType;

  StepLogEntry({
    required this.title,
    required this.start,
    this.stepType,
  });

  void endStep() {
    end = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'start': start.toIso8601String().split('.').first,
        'end': end?.toIso8601String().split('.').first,
        'durationSeconds': end?.difference(start).inSeconds,
        if (note != null) 'note': note,
        if (imagePath != null) 'imagePath': imagePath,
        if (stepType != null) 'type': stepType,
      };
}

class WorkflowLogger {
  Directory? _outputDirectory;
  final List<StepLogEntry> _steps = [];
  late DateTime _workflowStart;
  DateTime? _workflowEnd;
  final String workflowTitle;

  WorkflowLogger({required this.workflowTitle});

  Directory get outputDirectory => _outputDirectory!;

  Future<void> startWorkflow() async {
    _workflowStart = DateTime.now();
    await createOutputDirectory();
  }

  void endWorkflow() {
    _workflowEnd = DateTime.now();
  }

  void logStepStart(String title, {String? stepType}) {
    _steps.add(
        StepLogEntry(title: title, start: DateTime.now(), stepType: stepType));
  }

  void logStepEnd({String? note, String? imagePath}) {
    final step = _steps.last;
    step.endStep();
    if (note != null) step.note = note;
    if (imagePath != null) step.imagePath = imagePath;
  }

  Future<void> saveToFile() async {
    final data = {
      'workflowTitle': workflowTitle,
      'startTime': _workflowStart.toUtc().toIso8601String().split('.').first,
      'endTime': _workflowEnd?.toUtc().toIso8601String().split('.').first,
      'steps': _steps.map((e) => e.toJson()).toList(),
    };

    try {
      final file = File('${_outputDirectory!.path}/log.json');
      await file.writeAsString(jsonEncode(data));
      await MediaScanner.loadMedia(path: file.path);
    } catch (e) {
      print('Fehler beim Schreiben oder Registrieren der Log-Datei: $e');
    }
  }

  String _generateFilename() {
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    return '${workflowTitle}_$timestamp';
  }

  Future<void> createOutputDirectory() async {
    final baseDir = await getExternalStorageDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final folderName = '${workflowTitle}_$timestamp';
    _outputDirectory = Directory('${baseDir!.path}/$folderName');
    await _outputDirectory!.create(recursive: true);
  }
}
