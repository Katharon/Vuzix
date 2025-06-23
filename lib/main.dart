import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'display.dart';
import 'services/WorkflowManager.dart';

import 'input/device.dart';
import 'input/input_handler.dart';
import 'HelloWorldDemoPage.dart';
import 'keystroke_demo_page.dart';

import 'services/ConfigParser.dart';
import 'services/XmlManager.dart';
import 'services/WorkflowManager.dart';
import 'ui/LandingPage.dart';
import 'ConfigsOverview.dart';

Device theDevice = Device.conventional;
InputHandler inputHandler = InputHandler.fromDevice(theDevice);

late final WorkflowManager workflowManager; // ← hält aktive Workflows

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool supportedDevice = await setupDeviceAndInputHandling();
  runApp(
    supportedDevice
        ? const MyApp()
        : MaterialApp(
            home: Scaffold(body: Center(child: Text("unsupported device"))),
          ),
  );
}

Future<bool> setupDeviceAndInputHandling() async {
  bool supported = false;
  print('Platform: $defaultTargetPlatform');
  if (defaultTargetPlatform == TargetPlatform.android) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    print('Android model: ${androidInfo.model}');
    if (androidInfo.model == "Vuzix M4000") {
      theDevice = Device.m4000;
      supported = true;
    } else if (androidInfo.model == "Blade") {
      theDevice = Device.blade;
      supported = true;
    } else {
      theDevice = Device.conventional;
      supported = true;
    }
  } else if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
    theDevice = Device.conventional;
    supported = true;
  }

  if (!supported) {
    theDevice = Device.unsupported;
  }

  inputHandler = InputHandler.fromDevice(theDevice);
  ServicesBinding.instance.keyboard.addHandler(inputHandler.onKey);

  ServicesBinding.instance.keyboard.addHandler(inputHandler.onKey);

  // Workflows parsen und Manager bauen
  final parser = ConfigParser(XmlManager(), language: 'de');
  final workflows = [
    ...await parser.parse('assets/config/config_pc_anleitung.xml'), 
    ...await parser.parse('assets/config/config_med.xml')];
  workflowManager = WorkflowManager(workflows);

  debugPrint('WORKFLOWS: ${workflows.length}');
  debugPrint('STEPS   : ${workflows.first.steps.length}');
  debugPrint('TITLE   : ${workflows.first.steps.first.title}');

  // Falls keine Workflows, gilt das als „unsupported“
  return supported && workflows.isNotEmpty;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Vuzix Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.tealAccent,
            brightness: Brightness.dark,
          ).copyWith(surface: Colors.transparent),
          useMaterial3: true,
        ),
        home: ConfigsOverviewPage(manager: workflowManager),
      );
}
