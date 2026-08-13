import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/black_screen.dart';
import '../../../core/constants.dart';
import '../../content/domain/media_item.dart';

/// The slot is a fixed 10 seconds either way. A longer video gets cut off, a
/// shorter one holds its last frame. No looping, the assignment never asks for
/// it.
class VideoView extends StatefulWidget {
  const VideoView({required this.item, required this.onFinished, super.key});

  final MediaItem item;
  final VoidCallback onFinished;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  VideoPlayerController? _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // armed before opening the file, so a video that never loads still hands
    // the screen back on time
    _timer = Timer(kItemDuration, widget.onFinished);
    unawaited(_start());
  }

  Future<void> _start() async {
    final path = widget.item.localPath;
    if (path == null) return;

    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
    } on Exception {
      await controller.dispose();
      return; // stays black for the rest of the slot
    }

    // the widget can be gone by now, so dispose the controller here instead
    if (!mounted) {
      await controller.dispose();
      return;
    }

    await controller.setLooping(false);
    await controller.play();

    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const BlackScreen();
    return VideoSurface(controller: controller);
  }
}

/// Also used by the custom group for its video quadrant.
class VideoSurface extends StatelessWidget {
  const VideoSurface({required this.controller, super.key});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
