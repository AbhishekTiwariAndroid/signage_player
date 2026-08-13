import '../domain/content_repository.dart';
import '../domain/media_item.dart';
import 'content_json_source.dart';
import 'media_cache_store.dart';
import 'media_downloader.dart';

class ContentRepositoryImpl implements ContentRepository {
  const ContentRepositoryImpl({
    required this.jsonSource,
    required this.cacheStore,
    required this.downloader,
  });

  final ContentJsonSource jsonSource;
  final MediaCacheStore cacheStore;
  final MediaDownloader downloader;

  @override
  Future<List<MediaItem>> prepareContent() async {
    final playlist = jsonSource.read();
    if (playlist.isEmpty) return const [];

    await cacheStore.load();

    final targets = [
      for (final item in playlist) ...item.flattenDownloadable(),
    ];

    // all at once, not one after another. eagerError: false so one dead url
    // does not cancel the rest of the batch
    final paths = await Future.wait(
      targets.map(_ensureCached),
      eagerError: false,
    );

    final resolved = <String, String>{
      for (var i = 0; i < targets.length; i++)
        if (paths[i] case final String path) targets[i].url: path,
    };

    await cacheStore.rememberAll({
      for (final target in targets)
        if (resolved.containsKey(target.url)) target.url: target.type,
    });

    return [
      for (final item in playlist)
        if (_resolve(item, resolved) case final MediaItem ready) ready,
    ];
  }

  // returns null instead of throwing, so one failure stays with its own item
  Future<String?> _ensureCached(MediaItem item) async {
    try {
      final cached = await cacheStore.cachedPath(item.url, item.type);
      if (cached != null) return cached;

      final target = cacheStore.pathFor(item.url, item.type);
      await downloader.download(item.url, target);
      return target;
    } on Exception {
      return null;
    }
  }

  /// Attaches the local path, or returns null if the item has nothing playable
  /// left.
  MediaItem? _resolve(MediaItem item, Map<String, String> resolved) {
    if (item.type == MediaType.unknown) return null;

    if (item.type == MediaType.custom) {
      final children = [
        for (final child in item.children)
          if (_resolve(child, resolved) case final MediaItem ready) ready,
      ];

      // the group runs for the length of its video, so drop it without one
      final hasVideo = children.any((child) => child.type == MediaType.video);
      return hasVideo ? item.copyWith(children: children) : null;
    }

    final path = resolved[item.url];
    return path == null ? null : item.copyWith(localPath: path);
  }
}
