import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vuzix/StepsOverviewPage.dart';
import 'ConfigsOverview.dart';
import 'services/WorkflowManager.dart';
import 'services/ConfigParser.dart';
import 'services/XmlManager.dart';
import 'services/ConfigFileReader.dart';

class LanguagesListPage extends StatefulWidget {
  final WorkflowManager manager;
  final int workflowIndex;
  const LanguagesListPage(
      {super.key, required this.manager, required this.workflowIndex});

  @override
  State<LanguagesListPage> createState() => _LanguagesListPageState();
}

class _LanguagesListPageState extends State<LanguagesListPage> {
  int _selectedIndex = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) async {
    final workflow = widget.manager.workflows[widget.workflowIndex];
    final allLanguages = workflow.languages;
    if (allLanguages.isEmpty) return;
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % allLanguages.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + allLanguages.length) % allLanguages.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        await _selectLanguageAndNavigate(_selectedIndex);
      }
    }
  }

  Future<void> _selectLanguageAndNavigate(int index) async {
    final workflow = widget.manager.workflows[widget.workflowIndex];
    final allLanguages = workflow.languages;
    widget.manager.selectWorkflow(widget.workflowIndex);
    widget.manager.selectLanguage(allLanguages[index]);
    final parser = ConfigParser(XmlManager(), language: widget.manager.currentLanguage ?? 'de');
    final workflows = await parser.parse(workflow.sourceFile);
    widget.manager.setWorkflows(workflows, keepIndex: widget.workflowIndex);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StepsOverviewPage(manager: widget.manager),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final workflow = widget.manager.workflows[widget.workflowIndex];
    final allLanguages = workflow.languages;

    // Berechne die maximale Textbreite für mittige Anzeige
    final maxTextWidth = _getMaxTextWidth(context, allLanguages);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verfügbare Sprachen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Sprache setzen
            widget.manager.selectLanguage('de');
            // Alle Configs aus allen Dateien neu laden
            final xmlManager = XmlManager();
            final parser = ConfigParser(xmlManager, language: 'de');
            final configReader = ConfigFileReader(parser: parser);
            final workflows = await configReader.readAllWorkflows('assets/config');
            widget.manager.setWorkflows(workflows);

            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => ConfigsOverviewPage(manager: widget.manager),
                ),
                    (route) => false,
              );
            }
          },
        ),
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _handleKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 24), // Abstand zum oberen Rand
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allLanguages.length,
            itemBuilder: (context, index) {
              final selected = index == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () => _selectLanguageAndNavigate(index),
                  child: Container(
                    alignment: Alignment.center,
                    width: maxTextWidth + 32,
                    decoration: BoxDecoration(
                      color: selected ? Colors.teal[400] : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      allLanguages[index],
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : Colors.teal[900],
                      ),
                    ),
                    ),
                  ),
                );
            },
          ),
        ),
      ),
    );
  }

  double _getMaxTextWidth(BuildContext context, List<String> texts) {
    final style = Theme.of(context).textTheme.titleMedium ?? const TextStyle();
    double maxWidth = 0;
    for (final text in texts) {
      final width = (TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout())
          .width;
      if (width > maxWidth) maxWidth = width;
    }
    return maxWidth;
  }
}