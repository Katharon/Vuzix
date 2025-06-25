import '../models/Workflow.dart';
import '../models/WorkflowStep.dart';
import '../services/Logger.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Kümmert sich um:
/// * Welcher Workflow ist aktiv?
/// * Auf welchem Schritt befinden wir uns?
/// * Vor/Zurück springen – inklusive Condition-Check.
class WorkflowManager {
  /// Verlassene Schritte; oberstes Element = zuletzt verlassener Step.
  final List<int> _prevStack = <int>[];
  /// Schritte, die wir nach einem Zurück wieder vorwärts gehen können.
  final List<int> _forwardStack = <int>[];
  final List<Workflow> _workflows;
  final FlutterTts tts = FlutterTts();
  String? _currentLanguage;
  String? _selectedConfigPath;
  late WorkflowLogger _logger;

  int _wfIndex = 0;
  int _stepIndex = 0;
  bool _isLast = false;

  bool ttsEnabled = true;

  WorkflowManager(this._workflows) {
    if (_workflows.isEmpty) {
      throw ArgumentError('WorkflowManager braucht mindestens einen Workflow.');
    }
  }

  /* ---------- Getter ---------- */

  List<Workflow> get workflows => _workflows;

  Workflow get currentWorkflow => _workflows[_wfIndex];

  WorkflowStep get currentStep => currentWorkflow.steps[_stepIndex];

  int get currentWorkflowIndex => _wfIndex;

  int get currentStepIndex => _stepIndex;

  bool get hasForward => _forwardStack.isNotEmpty;

  bool get hasNext => hasForward || _stepIndex < currentWorkflow.steps.length - 1;

  bool get hasPrev => _prevStack.isNotEmpty;

  String? get currentLanguage => _currentLanguage;

  String? get selectedConfigPath => _selectedConfigPath;

  WorkflowLogger get logger => _logger;

  /* ---------- Steuerung ---------- */

  /// Anderen Workflow wählen (z. B. aus LandingPage).
  void selectWorkflow(int index) {
    if (index < 0 || index >= _workflows.length) {
      throw RangeError.index(index, _workflows, 'index');
    }
    _wfIndex = index;

    _stepIndex = 0;
    _prevStack.clear();
    _forwardStack.clear();

    // Logging starten
    _logger = WorkflowLogger(
      workflowTitle: currentWorkflow.title(_currentLanguage ?? 'de'),
    );
    _logger.startWorkflow();
    _logger.logStepStart(
      currentStep.title,
      stepType: currentStep.runtimeType.toString(),
    );
  }

  /// Ein Schritt zurück (falls möglich).
  void prev() {
    if (_isLast) _isLast = false;
    if (!hasPrev) return;

    _logger.logStepEnd();

    // aktuellen Step auf Forward‑Stack legen
    _forwardStack.add(_stepIndex);

    // letzten Step aus Prev‑Stack holen
    _stepIndex = _prevStack.removeLast();

    // Wenn wir jetzt auf einer Entscheidung stehen, Forward‑Stack verwerfen
    if (currentStep.nextConditions.length > 1) {
      _forwardStack.clear();
    }

    _logger.logStepStart(
      currentStep.title,
      stepType: currentStep.runtimeType.toString(),
    );
  }

  /// Einen Schritt vorwärts aus dem Forward‑Stack.
  void forward() {
    if (!hasForward) return;

    _logger.logStepEnd();

    _prevStack.add(_stepIndex);
    _stepIndex = _forwardStack.removeLast();

    _logger.logStepStart(
      currentStep.title,
      stepType: currentStep.runtimeType.toString(),
    );
  }

  /// Direkt zu einer Schritt-ID springen (z. B. aus <next>step_4</next>)
  void jumpTo(int id) {
    if (currentStep.stepId == id) return;

    final idx = currentWorkflow.steps.indexWhere((s) => s.stepId == id);
    if (idx < 0) return; // ungültige ID

    _logger.logStepEnd();

    _prevStack.add(_stepIndex);
    _forwardStack.clear(); // Neuer Pfad ⇒ alte „Zukunft“ vergessen

    _stepIndex = idx;

    _logger.logStepStart(
      currentStep.title,
      stepType: currentStep.runtimeType.toString(),
    );
  }

  /// Workflow neu starten.
  void reset() {
    _stepIndex = 0;
    _prevStack.clear();
    _forwardStack.clear();
  }

  void selectLanguage(String lang) {
    _currentLanguage = lang;
  }

  void selectConfigPath(String path) {
    _selectedConfigPath = path;
  }

  void setWorkflows(List<Workflow> workflows, {int? keepIndex}) {
    final oldIndex = keepIndex ?? _wfIndex;
    _workflows
      ..clear()
      ..addAll(workflows);

    _wfIndex = (oldIndex >= 0 && oldIndex < _workflows.length) ? oldIndex : 0;
    _stepIndex = 0;
    _prevStack.clear();
    _forwardStack.clear();
  }

  Future<void> completeWorkflow({String? imagePath}) async {
    _logger.logStepEnd(imagePath: imagePath);
    _logger.endWorkflow();
    await _logger.saveToFile();
  }

  Future<void> speak(String text) async {
    if (!ttsEnabled || _currentLanguage == null) return;

    await tts.stop();
    await tts.setLanguage(_currentLanguage!);
    await Future.delayed(const Duration(milliseconds: 100));
    await tts.speak(text);
  }

  void enableTts() {
    ttsEnabled = true;
  }

  void disableTts() {
    ttsEnabled = false;
    tts.stop();
  }
}
