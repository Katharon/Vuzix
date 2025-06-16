import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'input/device.dart';
import 'input/input_handler.dart';
import 'keystroke_demo_page.dart';
import 'camera_view_demo_page.dart';
import 'carousel_demo_page.dart';

Device theDevice = Device.conventional;
InputHandler inputHandler = InputHandler.fromDevice(theDevice);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool supportedDevice = await setupDeviceAndInputHandling();
  runApp(supportedDevice
      ? const MyApp()
      : MaterialApp(
          home: Scaffold(body: Center(child: Text("unsupported device")))));
}

Future<bool> setupDeviceAndInputHandling() async {
  // 1. find out what device we are running on
  bool supported = false;
  if (defaultTargetPlatform == TargetPlatform.android) {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    if (androidInfo.model == "Vuzix M4000") {
      theDevice = Device.m4000;
      supported = true;
    } else if (androidInfo.model == "Blade") {
      theDevice = Device.blade;
      supported = true;
    }
  } else if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
    theDevice = Device.conventional;
    supported = true;
  }

  if (!supported) {
    theDevice = Device.unsupported;
  }

  // 2. set up input handling (with translation for this device)
  inputHandler = InputHandler.fromDevice(theDevice);

  // 3. listen to the incoming events
  ServicesBinding.instance.keyboard.addHandler(inputHandler.onKey);

  return supported;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Flutter Vuzix Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.tealAccent, brightness: Brightness.dark)
              .copyWith(surface: Colors.transparent),
          useMaterial3: true,
        ),
        home: const KeyStrokeDemoPage(),
      );
}
