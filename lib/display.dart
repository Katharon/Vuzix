import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/WorkflowManager.dart';
import 'models/StepCondition.dart';

class DisplayWorkflow extends StatefulWidget {
  final WorkflowManager manager;
  const DisplayWorkflow({super.key, required this.manager});

  @override
  State<DisplayWorkflow> createState() => _DisplayWorkflowState();
}

class _DisplayWorkflowState extends State<DisplayWorkflow> {
  final ScrollController _scrollController = ScrollController();
  int _selectedOption = 0;

  void _scrollDown() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset < maxScroll) {
      _scrollController.animateTo(
        (_scrollController.offset + 100).clamp(0, maxScroll),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      _moveSelection(1);
    }
  }

  void _scrollUp() {
    if (_scrollController.offset > 0) {
      _scrollController.animateTo(
        (_scrollController.offset - 100)
            .clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    } else {
      _moveSelection(-1);
    }
  }

  void _moveSelection(int delta) {
    final step = widget.manager.currentStep;
    final optionsCount = step.nextConditions.length;
    if (optionsCount > 1) {
      setState(() {
        _selectedOption = (_selectedOption + delta).clamp(0, optionsCount - 1);
      });
    }
  }

  void _activateSelectedOption() {
    final step = widget.manager.currentStep;
    final optionsCount = step.nextConditions.length;
    if (optionsCount > 1) {
      final nextStepId = step.nextConditions[_selectedOption].nextStepId;
      widget.manager.jumpTo(nextStepId);
      setState(() {
        _selectedOption = 0;
      });
    }
  }

  void _goToNextStep() {
    final step = widget.manager.currentStep;
    final optionsCount = step.nextConditions.length;
    if (optionsCount == 1) {
      // Nur eine Option: wie gehabt
      final nextStepId = step.nextConditions.first.nextStepId;
      widget.manager.jumpTo(nextStepId);
      setState(() {
        _selectedOption = 0;
      });
    } else if (optionsCount > 1) {
      // Mehrere Optionen: gehe zu aktuell gewählter Option
      final nextStepId = step.nextConditions[_selectedOption].nextStepId;
      widget.manager.jumpTo(nextStepId);
      setState(() {
        _selectedOption = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.manager.currentStep;
    final optionsCount = step.nextConditions.length;
    final hasMultipleNexts = optionsCount > 1;

    return Scaffold(
      body: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _scrollDown();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _scrollUp();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (optionsCount > 0 && step.canProceed()) {
                _goToNextStep();
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (widget.manager.hasPrev) {
                setState(() {
                  widget.manager.prev();
                  _selectedOption = 0;
                });
              }
            } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space) {
              if (hasMultipleNexts) {
                _activateSelectedOption();
              }
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 48),
                      textStyle: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.manager.hasPrev
                        ? () {
                            setState(() {
                              widget.manager.prev();
                              _selectedOption = 0;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 28),
                    label: const Text(''),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(64, 48),
                      textStyle: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: optionsCount > 0 && step.canProceed()
                        ? () {
                            _goToNextStep();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward, size: 28),
                    label: const Text(''),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                step.title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: step.buildMedia(context),
                      ),
                      if (hasMultipleNexts)
                        Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(optionsCount, (i) {
                              final cond = step.nextConditions[i];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedOption == i
                                        ? const Color.fromARGB(
                                            255, 127, 127, 127)
                                        : Colors.grey[850],
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(120, 48),
                                    textStyle: const TextStyle(fontSize: 18),
                                    elevation: _selectedOption == i ? 6 : 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    widget.manager.jumpTo(cond.nextStepId);
                                    setState(() {
                                      _selectedOption = 0;
                                    });
                                  },
                                  child: Text(
                                    cond.condition?.isNotEmpty == true
                                        ? cond.condition!
                                        : 'Option ${i + 1}',
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
