import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/black_screen.dart';
import '../../../core/constants.dart';
import '../../content/domain/media_item.dart';
import 'custom_group_view.dart';
import 'image_view.dart';
import 'playback_providers.dart';
import 'video_view.dart';

/// Plays the playlist in an endless loop. Items are swapped by rebuilding
/// under a new key, so there is no PageView and no transition animation. The
/// key change is also what disposes the outgoing video controller.
class PlaybackScreen extends ConsumerStatefulWidget {
  const PlaybackScreen({super.key});

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  Timer? _watchdog;

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  void _advance() {
    _watchdog?.cancel();
    ref.read(playbackPositionProvider.notifier).advance();
  }

  // moves on by itself if a view never reports back, so a stalled file cannot
  // freeze the loop for good
  void _armWatchdog(Duration? slot) {
    if (!mounted) return;
    _watchdog?.cancel();
    _watchdog = Timer((slot ?? kUntimedItemCeiling) + kAdvanceGrace, _advance);
  }

  @override
  Widget build(BuildContext context) {
    final sequencer = ref.watch(playbackSequencerProvider);
    if (sequencer.isEmpty) return const BlackScreen();

    final position = ref.watch(playbackPositionProvider);
    final item = sequencer.itemAt(position);

    // after the frame, so the timer cannot fire mid build
    final slot = sequencer.slotDuration(item);
    WidgetsBinding.instance.addPostFrameCallback((_) => _armWatchdog(slot));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: KeyedSubtree(
          key: ValueKey('${position.cycle}:${position.index}'),
          child: _viewFor(item),
        ),
      ),
    );
  }

  Widget _viewFor(MediaItem item) => switch (item.type) {
    MediaType.image => ImageView(item: item, onFinished: _advance),
    MediaType.video => VideoView(item: item, onFinished: _advance),
    MediaType.custom => CustomGroupView(item: item, onFinished: _advance),
    MediaType.unknown => const BlackScreen(),
  };
}
