import 'package:flutter/material.dart';
import 'services/WorkflowManager.dart';
import 'LanguageOverview.dart';

class ConfigsOverviewPage extends StatelessWidget {
  final WorkflowManager manager;
  const ConfigsOverviewPage({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    final workflows = manager.workflows;

    return Scaffold(
      appBar: AppBar(title: const Text('Verfügbare Workflows')),
      body: ListView.builder(
        itemCount: workflows.length,
        itemBuilder: (context, index) {
          final workflow = workflows[index];
          return ListTile(
            title: Text('${workflow.names.values.first}'),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => LanguagesListPage(
                  manager: manager,
                  workflowIndex: index,
                ),
              ));
            },
          );
        },
      ),
    );
  }
}