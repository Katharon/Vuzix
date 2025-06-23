import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

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
        'start': start.toIso8601String(),
        'end': end?.toIso8601String(),
        'durationSeconds':
            end?.difference(start).inSeconds,
        if (note != null) 'note': note,
        if (imagePath != null) 'imagePath': imagePath,
        if (stepType != null) 'type': stepType,
      };
}

class WorkflowLogger {
  final List<StepLogEntry> _steps = [];
  late DateTime _workflowStart;
  DateTime? _workflowEnd;
  final String workflowTitle;

  WorkflowLogger({required this.workflowTitle});

  void startWorkflow() {
    _workflowStart = DateTime.now();
  }

  void endWorkflow() {
    _workflowEnd = DateTime.now();
  }

  void logStepStart(String title, {String? stepType}) {
    _steps.add(StepLogEntry(title: title, start: DateTime.now(), stepType: stepType));
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
      'startTime': _workflowStart.toIso8601String(),
      'endTime': _workflowEnd?.toIso8601String(),
      'steps': _steps.map((e) => e.toJson()).toList(),
    };

    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/${_generateFilename()}.json');
    await file.writeAsString(jsonEncode(data));
  }

  String _generateFilename() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    return '${workflowTitle}_$timestamp';
  }
}
