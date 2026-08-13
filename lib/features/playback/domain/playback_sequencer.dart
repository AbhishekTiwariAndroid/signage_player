import '../../../core/constants.dart';
import '../../content/domain/media_item.dart';

/// [cycle] counts completed passes through the playlist, so two visits to the
/// same index still give different widget keys.
class PlaybackPosition {
  const PlaybackPosition({this.index = 0, this.cycle = 0});

  final int index;
  final int cycle;

  @override
  bool operator ==(Object other) =>
      other is PlaybackPosition && other.index == index && other.cycle == cycle;

  @override
  int get hashCode => Object.hash(index, cycle);

  @override
  String toString() => 'PlaybackPosition(index: $index, cycle: $cycle)';
}

/// The loop rules, kept out of the widgets so they can be tested directly.
class PlaybackSequencer {
  const PlaybackSequencer(this.items);

  final List<MediaItem> items;

  bool get isEmpty => items.isEmpty;

  MediaItem itemAt(PlaybackPosition position) => items[position.index];

  /// Wraps back to the start, so the loop never ends.
  PlaybackPosition next(PlaybackPosition current) {
    final isLast = current.index >= items.length - 1;
    return PlaybackPosition(
      index: isLast ? 0 : current.index + 1,
      cycle: isLast ? current.cycle + 1 : current.cycle,
    );
  }

  /// Null for a custom group, which runs for the length of its video. That is
  /// not known until the video has been opened, so the view decides instead.
  Duration? slotDuration(MediaItem item) =>
      item.type == MediaType.custom ? null : kItemDuration;
}
