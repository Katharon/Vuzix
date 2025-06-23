import 'package:flutter/material.dart';

import '../services/WorkflowManager.dart';

class LandingPage extends StatelessWidget {
  final WorkflowManager workflowManager;

  const LandingPage({super.key, required this.workflowManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vuzix Workflow Demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to the Vuzix Workflow Demo!",
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to the workflow list or start a workflow
              },
              child: const Text("Start Workflow"),
            ),
          ],
        ),
      ),
    );
  }
}