import 'package:flutter/material.dart';

import 'main.dart';
import 'ui/snackbar.dart';

class KeyStrokeDemoPage extends StatefulWidget {
  const KeyStrokeDemoPage({super.key});

  @override
  State<KeyStrokeDemoPage> createState() => _KeyStrokeDemoPageState();
}

class _KeyStrokeDemoPageState extends State<KeyStrokeDemoPage> {
  List<String> _keyEvents = [];

  @override
  void initState() {
    super.initState();

    inputHandler.keys.listen((event) {
      setState(() {
        _keyEvents.add(event.name);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Flutter Vuzix Demo - Keystrokes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pressed these keys (last 10):',
            ),
            ..._keyEvents.reversed.take(10).map((e) => Text(e)),
          ],
        ),
      ),
    );
  }
}
