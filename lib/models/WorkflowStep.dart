import 'package:flutter/widgets.dart';
import 'package:flutter_vuzix/models/StepCondition.dart';
import 'MediaType.dart';

class WorkflowStep {
  final int stepId;
  final String title;
  final MediaType media;
  final List<StepCondition> nextConditions;

  const WorkflowStep({
    required this.stepId,
    required this.title,
    required this.media,
    this.nextConditions = const [],
  });

  /// TRUE, wenn alle Bedingungen erfüllt sind oder keine existieren.
  bool canProceed() => nextConditions.length == 1;

  /// Convenience-Delegation (damit StepPage sauber bleibt).
  Widget buildMedia(BuildContext ctx) => media.build(ctx);
}