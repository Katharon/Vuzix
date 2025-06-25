import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/WorkflowManager.dart';
import 'display.dart';
import 'services/ConfigFileReader.dart';
import 'services/XmlManager.dart';
import 'services/ConfigParser.dart';
import 'LanguageOverview.dart';

class StepsOverviewPage extends StatefulWidget {
  final WorkflowManager manager;

  const StepsOverviewPage({super.key, required this.manager});

  @override
  State<StepsOverviewPage> createState() => _StepsOverviewPageState();
}

class _StepsOverviewPageState extends State<StepsOverviewPage> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  static const _swipeVelocity = 300; // Mindestgeschwindigkeit für Swipe-Erkennung

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final steps = widget.manager.currentWorkflow.steps;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _selectedIndex = (_selectedIndex + 1) % steps.length);
        _scrollToSelected();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _selectedIndex = (_selectedIndex - 1 + steps.length) % steps.length);
        _scrollToSelected();
      }
    }
  }

  void _scrollToSelected() {
    const itemHeight = 80.0;
    final screenHeight = MediaQuery.of(context).size.height;
    final scrollPosition = (_selectedIndex * itemHeight) - (screenHeight / 2) + (itemHeight / 2);

    _scrollController.animateTo(
      scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _handleHorizontalSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < -_swipeVelocity) {
      // Nach links wischen → Weiter in den Workflow
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DisplayWorkflow(manager: widget.manager)),
      );
    } else if (details.primaryVelocity! > _swipeVelocity) {
      // Nach rechts wischen → Zurück (falls gewünscht)
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.manager.currentWorkflow.steps;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verfügbare Steps'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Sprache setzen
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => LanguagesListPage(manager: widget.manager, workflowIndex: widget.manager.currentWorkflowIndex),
                ),
                    (route) => false,
              );
            }
          },
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: _handleHorizontalSwipe,
        child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: _handleKeyEvent,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: index == _selectedIndex ? Colors.teal[400] : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  enabled: false,          // <-- Klicks deaktiviert
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 18,
                      color: index == _selectedIndex ? Colors.white : null,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}