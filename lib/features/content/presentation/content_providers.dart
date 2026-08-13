import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../data/content_json_source.dart';
import '../data/content_repository_impl.dart';
import '../data/media_cache_store.dart';
import '../data/media_downloader.dart';
import '../domain/content_repository.dart';
import '../domain/media_item.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final contentJsonSourceProvider = Provider<ContentJsonSource>(
  (ref) => const ContentJsonSource(),
);

final mediaCacheStoreProvider = Provider<MediaCacheStore>(
  (ref) => MediaCacheStore(),
);

final mediaDownloaderProvider = Provider<MediaDownloader>(
  (ref) => MediaDownloader(ref.watch(httpClientProvider)),
);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(
    jsonSource: ref.watch(contentJsonSourceProvider),
    cacheStore: ref.watch(mediaCacheStoreProvider),
    downloader: ref.watch(mediaDownloaderProvider),
  ),
);

// The download phase. Stays in its loading state until every file is done,
// which is exactly how long the splash screen shows. No separate flag needed.
final preparedContentProvider = FutureProvider<List<MediaItem>>(
  (ref) => ref.watch(contentRepositoryProvider).prepareContent(),
);
