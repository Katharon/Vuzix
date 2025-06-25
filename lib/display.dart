import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vuzix/main.dart';
import 'package:flutter_vuzix/multimodal/qr_code.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/WorkflowManager.dart';
import 'models/TextMedia.dart';
import 'ui/CameraCapturePage.dart';
import 'models/StepCondition.dart';
import 'multimodal/stt.dart';
import 'multimodal/tts.dart';

class DisplayWorkflow extends StatefulWidget {
  final WorkflowManager manager;
  const DisplayWorkflow({super.key, required this.manager});

  @override
  State<DisplayWorkflow> createState() => _DisplayWorkflowState();
}

class _DisplayWorkflowState extends State<DisplayWorkflow> {
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedOption = 0;
  final _stt = STT.instance;
  StreamSubscription<bool>? _nextSub;
  StreamSubscription<bool>? _prevSub;
  bool _qrVisible = true;

  @override
  void dispose() {
    for (final s in [_nextSub, _prevSub]) {
      s?.cancel();
    }

    super.dispose();
  }

  // Diese Methode berechnet den Pfad von Anfang bis zum aktuellen Step
  List<int> _collectPathToCurrentStep() {
    final steps = widget.manager.currentWorkflow.steps;
    final path = <int>[];
    int currentIndex = 0;
    int currentStepId = steps[currentIndex].stepId;
    path.add(currentStepId);

    while (currentStepId != widget.manager.currentStep.stepId) {
      final step = steps.firstWhere((s) => s.stepId == currentStepId);
      if (step.nextConditions.isEmpty) break;
      int nextStepId;
      if (step.nextConditions.length == 1) {
        nextStepId = step.nextConditions.first.nextStepId;
      } else {
        // Wenn mehrere Möglichkeiten, nimm die, die zum aktuellen Step führt
        // oder einfach die erste, falls nicht auffindbar
        final idx = steps
            .indexWhere((s) => s.stepId == widget.manager.currentStep.stepId);
        if (idx != -1) {
          final possible = step.nextConditions
              .where((c) => c.nextStepId == steps[idx].stepId)
              .toList();
          nextStepId = possible.isNotEmpty
              ? possible.first.nextStepId
              : step.nextConditions.first.nextStepId;
        } else {
          nextStepId = step.nextConditions.first.nextStepId;
        }
      }
      path.add(nextStepId);
      currentStepId = nextStepId;
      if (path.length > steps.length) break; // Schutz vor Endlosschleife
    }
    return path;
  }

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
      _speakCurrentStep();
    }
  }

  Future<void> _playSoundNext() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource("resources/sounds/success_sound.mp3"));
  }

  Future<void> _playSoundQRCodeScanned() async {
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource("resources/sounds/camera_sound.mp3"));
  }

  Future<void> _goToNextStep() async {
    final step = widget.manager.currentStep;
    final optionsCount = step.nextConditions.length;

    // Prüfe, ob dies der letzte Step ist (keine nextConditions oder ungültige nextStepId)
    bool isLastStep = false;
    if (optionsCount == 0) {
      isLastStep = true;
    } else {
      // Prüfe, ob alle nextStepIds ungültig sind
      final workflowStepIds =
          widget.manager.currentWorkflow.steps.map((s) => s.stepId).toSet();
      if (step.nextConditions
          .every((c) => !workflowStepIds.contains(c.nextStepId))) {
        isLastStep = true;
      }
    }

    if (isLastStep) {
      setState(() {
        _qrVisible = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Workflow abschließen?'),
          content: const Text('Möchten Sie den Workflow wirklich abschließen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Nein'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CameraCapturePage(
                    saveDirectory: widget.manager.logger.outputDirectory,
                    onImageConfirmed: (path) {
                      widget.manager.completeWorkflow(imagePath: path);
                    },
                  ),
                ));
              },
              child: const Text('Ja'),
            ),
          ],
        ),
      );
      return;
    }

    // Standard-Weiter-Logik
    if (optionsCount == 1) {
      final nextStepId = step.nextConditions.first.nextStepId;
      widget.manager.jumpTo(nextStepId);
      setState(() {
        _selectedOption = 0;
      });
      await _playSoundNext();
      _speakCurrentStep();
    } else if (optionsCount > 1) {
      final nextStepId = step.nextConditions[_selectedOption].nextStepId;
      widget.manager.jumpTo(nextStepId);
      setState(() {
        _selectedOption = 0;
      });
      await _playSoundNext();
      _speakCurrentStep();
    }
  }

  /* ===================================  init / dispose ========= */
  @override
  void initState() {
    super.initState();

    _speakCurrentStep();

    if (theDevice.name == "Vuzix M4000" || theDevice.name == "Blade") {
      // 1) STT initialisieren und Kommandos registrieren
      _stt.init(initialPhrases: ['weiter', 'retour', 'tts an', 'tts aus']);

      // 2) → "weiter" (Wake-Word "Hello Vuzix" muss erst gesprochen werden)
      _nextSub = _stt.listenFor('weiter').listen((hit) {
        if (hit) _goToNextStep();
      });

      // 3) → “zurück”
      _prevSub = _stt.listenFor('retour').listen((hit) {
        if (hit && widget.manager.hasPrev) {
          setState(() {
            widget.manager.prev();
            _selectedOption = 0;
          });
        }
      });

      _stt.listenFor('tts an').listen((hit) {
        if (hit && !workflowManager.ttsEnabled) {
          setState(() async {
            workflowManager.enableTts();
          });
        }
      });

    _stt.listenFor('tts aus').listen((hit) {
        if (hit && workflowManager.ttsEnabled) {
          setState(() {
            workflowManager.disableTts();
          });
        }
      });
    }
  }

  void _speakCurrentStep() async {
    await widget.manager.tts.stop();
    await Future.delayed(const Duration(milliseconds: 100));
    final step = widget.manager.currentStep;
    final text = step.title;
    await widget.manager.speak('');
    await widget.manager.speak(text);

    if (step.media is TextMedia) {
      final textMedia = step.media as TextMedia;
      await widget.manager.speak(textMedia.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.manager.currentStep;
    final optionsCount = step.nextConditions.length;
    final hasMultipleNexts = optionsCount > 1;
    bool _isScanning = false;

    // Nutze den Pfad von Anfang bis zum aktuellen Step
    final pathStepIds = _collectPathToCurrentStep();
    final currentStepNumber = pathStepIds.length;
    final totalSteps = widget.manager.currentWorkflow.steps.length;

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
                _speakCurrentStep();
              }
            } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space ||
                event.logicalKey == LogicalKeyboardKey.select) {
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  value: (totalSteps > 1)
                      ? (currentStepNumber == totalSteps
                          ? 1.0
                          : (currentStepNumber) / (totalSteps - 2))
                      : 1.0,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
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
                            _speakCurrentStep();
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 28),
                    label: const Text(''),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        workflowManager.ttsEnabled = !workflowManager.ttsEnabled;
                        if (!workflowManager.ttsEnabled){
                          workflowManager.disableTts();
                        }
                      });
                    },
                    child: Text(workflowManager.ttsEnabled ? 'tts: an' : 'tts: aus'),
                  ),
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: QRScanner(
                        rotateCamera: true,
                        isVisible: _qrVisible,
                        onScan: (link) async {
                          if (_isScanning) return;
                          _isScanning = true;

                          await _playSoundQRCodeScanned();

                          if (link == "Weiter") {
                            await Future.delayed(const Duration(seconds: 2));
                            await _goToNextStep();
                          }

                          _isScanning = false;
                        }),
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
              const SizedBox(height: 1),
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
                                    _speakCurrentStep();
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
