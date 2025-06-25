import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'MediaType.dart';

class VideoMedia extends MediaType {
  final String assetPath;

  const VideoMedia({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return _VideoPlayerWidget(assetPath: assetPath);
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String assetPath;
  const _VideoPlayerWidget({required this.assetPath});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : const CircularProgressIndicator(),
    );
  }
}
