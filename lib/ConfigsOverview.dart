import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/WorkflowManager.dart';
import 'LanguageOverview.dart';

class ConfigsOverviewPage extends StatefulWidget {
  final WorkflowManager manager;
  const ConfigsOverviewPage({super.key, required this.manager});

  @override
  State<ConfigsOverviewPage> createState() => _ConfigsOverviewPageState();
}

class _ConfigsOverviewPageState extends State<ConfigsOverviewPage> {
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

  void _handleKey(RawKeyEvent event) {
    final workflows = widget.manager.workflows;
    if (workflows.isEmpty) return;
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % workflows.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + workflows.length) % workflows.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.select) {
        final workflow = widget.manager.workflows[_selectedIndex];
        widget.manager.selectConfigPath(workflow.sourceFile);
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => LanguagesListPage(
            manager: widget.manager,
            workflowIndex: _selectedIndex,
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflows = widget.manager.workflows;
    final titles = workflows.map((w) => w.names.values.first.toString()).toList();
    final maxTextWidth = _getMaxTextWidth(context, titles);

    return Scaffold(
      appBar: AppBar(title: const Text('Verfügbare Workflows')),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _handleKey,
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: workflows.length,
            itemBuilder: (context, index) {
              final workflow = workflows[index];
              final selected = index == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  onTap: () {
                  final workflow = widget.manager.workflows[index];
                  widget.manager.selectConfigPath(workflow.sourceFile); 
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => LanguagesListPage(
                        manager: widget.manager,
                        workflowIndex: index,
                      ),
                    ));
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: maxTextWidth + 32,
                    decoration: BoxDecoration(
                      color: selected ? Colors.teal[400] : null,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      workflow.names.values.first,
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
      )..layout()).width;
      if (width > maxWidth) maxWidth = width;
    }
    return maxWidth;
  }
}