import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'main.dart';
import 'ui/snackbar.dart';
import 'multimodal/stt.dart';
import 'multimodal/qr_code.dart';
import 'multimodal/tts.dart';

class KeyStrokeDemoPage extends StatefulWidget {
  const KeyStrokeDemoPage({super.key});

  @override
  State<KeyStrokeDemoPage> createState() => _KeyStrokeDemoPageState();
}

/* ------------------------------------------------------------------- */

class _KeyStrokeDemoPageState extends State<KeyStrokeDemoPage> {
  final List<String> _keyEvents = [];
  String? _qrCodeContent;
  String _lastSpoken = '';

  @override
  void initState() {
    super.initState();

    inputHandler.keys.listen((event) {
      setState(() {
        _keyEvents.add(event.name);
      });

      speak(event.name);
    });
    
    _initSpeech();
  }

  /* ---------------- QR-Callback ----------------- */
  void _handleQR(String code) {
    setState(() => _qrCodeContent = code);
  }

  /* ---------------- UI ------------------------- */
  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mikrofon-Zugriff verweigert')),
        );
      }
      return;
    }

    // await STT.instance.init(onSpeech: _handleSpeech);
  }

  void _handleSpeech(String text) {
    setState(() => _lastSpoken = text);

    if (text.contains('weiter')) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('🎤 „weiter“ erkannt')));
    }
  }

  @override
  void dispose() {
    // STT.instance.dispose();
    super.dispose();
  }

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Vuzix Demo - Keystrokes & QR Scanner'),
      ),
      body: Column(
        children: [
          // QR-Code Scanner Bereich (oberer Teil)
          SizedBox(
            height: 250,
            child: QRScanner(
              rotateCamera: false,
              height: 250,
              isVisible: true,
              onScan: _handleQR,
            ),
          ),
          const Divider(),
          // Tasteneingaben und QR-Content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('You have pressed these keys (last 10):'),
                  ..._keyEvents.reversed.take(10).map((e) => Text(e)),
                  const SizedBox(height: 20),
                  const Text('Scanned QR Code:'),
                  Text(
                    _qrCodeContent ?? 'No QR code scanned yet.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}