import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:media_scanner/media_scanner.dart';

class CameraCapturePage extends StatefulWidget {
  final void Function(String imagePath) onImageConfirmed;
  final Directory saveDirectory;

  const CameraCapturePage({
    super.key,
    required this.onImageConfirmed,
    required this.saveDirectory,
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera(); // <- Zuweisung
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _controller = CameraController(camera, ResolutionPreset.medium);
    await _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    await _initializeControllerFuture;
    final file = await _controller.takePicture();
    setState(() {
      _capturedFile = file;
    });
  }

  Future<void> _confirmPicture() async {
    if (_capturedFile != null) {
      final savedPath = p.join(widget.saveDirectory.path, 'photo.jpg');
      // Bild einlesen
      final bytes = await _capturedFile!.readAsBytes();
      final original = img.decodeImage(bytes);

      final fixed = img.copyRotate(original!, angle: 90);

      final fixedFile = File(savedPath);
      await fixedFile.writeAsBytes(img.encodeJpg(fixed));

      await MediaScanner.loadMedia(path: savedPath);

      widget.onImageConfirmed(savedPath);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Foto aufnehmen')),
      body: _capturedFile == null
          ? FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )
          : Column(
              children: [
                Expanded(child: Image.file(File(_capturedFile!.path))),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text("Verwenden"),
                      onPressed: _confirmPicture,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Neu"),
                      onPressed: () {
                        setState(() {
                          _capturedFile = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: _capturedFile == null
          ? FloatingActionButton(
              onPressed: _takePicture,
              child: const Icon(Icons.camera),
            )
          : null,
    );
  }
}
