import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/black_screen.dart';
import '../../../core/constants.dart';
import '../../content/domain/media_item.dart';
import 'image_view.dart';
import 'video_view.dart';

/// The video and all three images at the same time, in four equal quadrants:
///
/// ```
/// +---------+---------+
/// |  video  | slot 0  |
/// +---------+---------+
/// | slot 1  | slot 2  |
/// +---------+---------+
/// ```
///
/// The three image slots share one timer and shift by one position every 5
/// seconds, so a 20 second video gives 4 rotations. The video's length decides
/// how long the whole group stays on screen.
class CustomGroupView extends StatefulWidget {
  const CustomGroupView({
    required this.item,
    required this.onFinished,
    super.key,
  });

  final MediaItem item;
  final VoidCallback onFinished;

  @override
  State<CustomGroupView> createState() => _CustomGroupViewState();
}

class _CustomGroupViewState extends State<CustomGroupView> {
  VideoPlayerController? _controller;
  Timer? _rotation;
  Timer? _fallback;
  bool _finished = false;
  int _offset = 0;

  late final List<MediaItem> _images = [
    for (final child in widget.item.children)
      if (child.type == MediaType.image && child.isReady) child,
  ];

  late final MediaItem? _video = _firstPlayableVideo();

  @override
  void initState() {
    super.initState();
    if (_images.isNotEmpty) {
      _rotation = Timer.periodic(kImageRotation, (_) {
        setState(() => _offset++);
      });
    }
    unawaited(_startVideo());
  }

  MediaItem? _firstPlayableVideo() {
    for (final child in widget.item.children) {
      if (child.type == MediaType.video && child.isReady) return child;
    }
    return null;
  }

  Future<void> _startVideo() async {
    final path = _video?.localPath;
    if (path == null) {
      _finishAfter(kFailedItemSkipDelay);
      return;
    }

    final controller = VideoPlayerController.file(File(path));
    try {
      await controller.initialize();
    } on Exception {
      await controller.dispose();
      _finishAfter(kFailedItemSkipDelay);
      return;
    }

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

    // assigned before the listener, so the first callback already sees it
    _controller = controller;
    controller.addListener(_checkCompletion);

    // backup, in case the listener never reports the end
    _finishAfter(controller.value.duration + kAdvanceGrace);
    setState(() {});
  }

  void _checkCompletion() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    if (value.isPlaying || value.position < value.duration) return;
    _finish();
  }

  void _finishAfter(Duration delay) {
    _fallback?.cancel();
    _fallback = Timer(delay, _finish);
  }

  // only fires once, however many of the safeguards go off
  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _rotation?.cancel();
    _fallback?.cancel();
    _controller?.removeListener(_checkCompletion);
    _controller?.dispose();
    super.dispose();
  }

  Widget _imageSlot(int slot) {
    if (_images.isEmpty) return const BlackScreen();
    final image = _images[(_offset + slot) % _images.length];
    return LocalImage(path: image.localPath!);
  }

  Widget get _videoSlot {
    final controller = _controller;
    if (controller == null) return const BlackScreen();
    return VideoSurface(controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _videoSlot),
                Expanded(child: _imageSlot(0)),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _imageSlot(1)),
                Expanded(child: _imageSlot(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
