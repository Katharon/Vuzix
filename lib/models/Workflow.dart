import 'WorkflowStep.dart';

class Workflow {
  final List<String> languages;
  final List<WorkflowStep> steps;
  final Map<String, String> names;

  const Workflow({
    required this.languages,
    required this.steps,
    required this.names,
  });

  /// Hole Step per ID oder Index, wie es dir lieber ist.
  WorkflowStep? stepById(int id) =>
      steps.firstWhere((s) => s.stepId == id, orElse: () => steps.first);

  /// Erstes Element, falls du einen Einstieg brauchst.
  WorkflowStep get firstStep => steps.first;

  /// Gibt den Titel in der gewünschten Sprache zurück,
  /// fallback auf erste verfügbare, falls nicht vorhanden.
  String title(String lang) =>
      names[lang] ?? names[languages.first] ?? 'Unnamed';
}