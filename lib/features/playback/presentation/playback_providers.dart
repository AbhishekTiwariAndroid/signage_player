import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/domain/media_item.dart';
import '../../content/presentation/content_providers.dart';
import '../domain/playback_sequencer.dart';

// Playback is only built after the downloads are done, so the other states
// just resolve to an empty playlist.
final playbackSequencerProvider = Provider<PlaybackSequencer>((ref) {
  final playlist = switch (ref.watch(preparedContentProvider)) {
    AsyncData(:final value) => value,
    _ => const <MediaItem>[],
  };
  return PlaybackSequencer(playlist);
});

/// What is on screen right now. Advanced by whichever view is playing, once it
/// reports that its turn is over.
final playbackPositionProvider =
    NotifierProvider<PlaybackNotifier, PlaybackPosition>(PlaybackNotifier.new);

class PlaybackNotifier extends Notifier<PlaybackPosition> {
  @override
  PlaybackPosition build() => const PlaybackPosition();

  void advance() {
    state = ref.read(playbackSequencerProvider).next(state);
  }
}
