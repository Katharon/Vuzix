import 'package:flutter/material.dart';
import 'services/WorkflowManager.dart';
import 'services/ConfigParser.dart';
import 'services/XmlManager.dart';
import 'display.dart';

class LanguagesListPage extends StatelessWidget {
  final WorkflowManager manager;
  final int workflowIndex;
  const LanguagesListPage({super.key, required this.manager, required this.workflowIndex});

  @override
  Widget build(BuildContext context) {
    final workflow = manager.workflows[workflowIndex];
    final allLanguages = workflow.languages;

    return Scaffold(
      appBar: AppBar(title: const Text('Verfügbare Sprachen')),
      body: ListView.builder(
        itemCount: allLanguages.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(allLanguages[index]),
          onTap: () async {
            manager.selectWorkflow(workflowIndex);
            manager.selectLanguage(allLanguages[index]);
            // Workflows neu parsen mit gewählter Sprache:
            final parser = ConfigParser(XmlManager(), language: manager.currentLanguage ?? 'de');
            final workflows = await parser.parse('assets/config/config_pc_anleitung.xml');
            manager.setWorkflows(workflows);
            // Dann weiter zur Anzeige
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DisplayWorkflow(manager: manager),
            ));
          },
        ),
      ),
    );
  }
}