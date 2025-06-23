import '../models/Workflow.dart';
import '../models/WorkflowStep.dart';

/// Kümmert sich um:
/// * Welcher Workflow ist aktiv?
/// * Auf welchem Schritt befinden wir uns?
/// * Vor/Zurück springen – inklusive Condition-Check.
class WorkflowManager {
  final List<Workflow> _workflows;
  String? _currentLanguage;

  int _wfIndex = 0;
  int _stepIndex = 0;

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

  bool get hasNext => _stepIndex < currentWorkflow.steps.length - 1;

  bool get hasPrev => _stepIndex > 0;

    String? get currentLanguage => _currentLanguage;

  /* ---------- Steuerung ---------- */

  /// Anderen Workflow wählen (z. B. aus LandingPage).
  void selectWorkflow(int index) {
    if (index < 0 || index >= _workflows.length) {
      throw RangeError.index(index, _workflows, 'index');
    }
    _wfIndex = index;
    _stepIndex = 0;
  }

  /// Ein Schritt nach vorne. Gibt false zurück, falls Bedingungen nicht erfüllt.
  bool next() {
    if (!currentStep.canProceed() || !hasNext) return false;
    _stepIndex++;
    return true;
  }

  /// Ein Schritt zurück (falls möglich).
  void prev() {
    if (hasPrev) _stepIndex--;
  }

  /// Direkt zu einer Schritt-ID springen (z. B. aus <next>step_4</next>)
  void jumpTo(int id) {
    final idx = currentWorkflow.steps.indexWhere((s) => s.stepId == id);
    if (idx >= 0) _stepIndex = idx;
  }

  /// Workflow neu starten.
  void reset() => _stepIndex = 0;

  void selectLanguage(String lang) {
    _currentLanguage = lang;
  }

  void setWorkflows(List<Workflow> workflows) {
    _workflows
      ..clear()
      ..addAll(workflows);
    _wfIndex = 0;
    _stepIndex = 0;
  }
}