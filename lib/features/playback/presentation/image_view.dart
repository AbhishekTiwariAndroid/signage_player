import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/black_screen.dart';
import '../../../core/constants.dart';
import '../../content/domain/media_item.dart';

class ImageView extends StatefulWidget {
  const ImageView({required this.item, required this.onFinished, super.key});

  final MediaItem item;
  final VoidCallback onFinished;

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // a broken file still holds its slot, so the loop keeps a steady rhythm
    _timer = Timer(kItemDuration, widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.item.localPath;
    if (path == null) return const BlackScreen();
    return LocalImage(path: path);
  }
}

/// Also used by the custom group for its three quadrants. `cover` because the
/// assignment says fill the screen, so cropping is better than black bars.
class LocalImage extends StatelessWidget {
  const LocalImage({required this.path, super.key});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // keeps the old frame while the next one decodes, so the rotating
        // quadrants do not flash black
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const BlackScreen(),
      ),
    );
  }
}
