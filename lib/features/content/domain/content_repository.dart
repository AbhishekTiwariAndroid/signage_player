import 'media_item.dart';

abstract class ContentRepository {
  /// Reads the playlist and downloads whatever is not cached yet. Resolves
  /// only after every download has settled. Entries that could not be fetched
  /// are dropped, so the result is always playable offline.
  Future<List<MediaItem>> prepareContent();
}
