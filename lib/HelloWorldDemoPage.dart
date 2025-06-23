import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class HelloWorldDemoPage extends StatefulWidget {
  const HelloWorldDemoPage({super.key});

  @override
  State<HelloWorldDemoPage> createState() => _HelloWorldDemoPageState();
}

class _HelloWorldDemoPageState extends State<HelloWorldDemoPage> {
  int selectedIndex = 0; // 0 = A, 1 = B, 2 = C
  String? selection;
  final FocusNode _focusNode = FocusNode();
  VideoPlayerController? _videoController;

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
    _videoController?.dispose();
    super.dispose();
  }

  void _handleKey(RawKeyEvent event) {
    if (selection == null && event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          selectedIndex = (selectedIndex - 1) < 0 ? 2 : selectedIndex - 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          selectedIndex = (selectedIndex + 1) > 2 ? 0 : selectedIndex + 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        setState(() {
          if (selectedIndex == 0) {
            selection = 'A';
          } else if (selectedIndex == 1) {
            selection = 'Hier wird ein Bild angezeigt';
          } else if (selectedIndex == 2) {
            selection = 'Hier ist ein Video';
            _videoController = VideoPlayerController.asset(
              'assets/resources/video/exampleVideo.mp4',
            )..initialize().then((_) {
                setState(() {});
                _videoController?.play();
              });
          }
        });
      }
    }
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selection = null;
            _videoController?.pause();
            _videoController?.seekTo(Duration.zero);
          });
        },
        child: const Text('Zurück'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (selection == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hello World Demo')),
        body: Center(
          child: Focus(
            focusNode: _focusNode,
            onKey: (_, event) {
              _handleKey(event);
              return KeyEventResult.handled;
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('hello world widget'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedIndex == 0
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor:
                            selectedIndex == 0 ? Colors.white : null,
                      ),
                      onPressed: () {
                        setState(() {
                          selection = 'A';
                        });
                      },
                      child: const Text('Gehe zu A'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedIndex == 1
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor:
                            selectedIndex == 1 ? Colors.white : null,
                      ),
                      onPressed: () {
                        setState(() {
                          selection = 'Hier wird ein Bild angezeigt';
                        });
                      },
                      child: const Text('Gehe zu B'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedIndex == 2
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor:
                            selectedIndex == 2 ? Colors.white : null,
                      ),
                      onPressed: () {
                        setState(() {
                          selection = 'Hier ist ein Video';
                          _videoController = VideoPlayerController.asset(
                            'assets/resources/video/exampleVideo.mp4',
                          )..initialize().then((_) {
                              setState(() {});
                              _videoController?.play();
                            });
                        });
                      },
                      child: const Text('Gehe zu C'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Mit Links/Rechts auswählen, mit Enter bestätigen!'),
              ],
            ),
          ),
        ),
      );
    } else if (selection == 'Hier wird ein Bild angezeigt') {
      return Scaffold(
        appBar: AppBar(title: const Text('Hello World Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/resources/images/exmapleImage.jpg',
                width: 300,
                fit: BoxFit.contain,
              ),
              _buildBackButton(),
            ],
          ),
        ),
      );
    } else if (selection == 'Hier ist ein Video') {
      return Scaffold(
        appBar: AppBar(title: const Text('Hello World Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _videoController != null && _videoController!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const CircularProgressIndicator(),
              _buildBackButton(),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text('Hello World Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                selection!,
                style: const TextStyle(fontSize: 32),
              ),
              _buildBackButton(),
            ],
          ),
        ),
      );
    }
  }
}
