enum MediaType {
  image,
  video,
  custom,
  unknown;

  // unknown instead of throwing, so one bad entry cannot break the playlist
  static MediaType fromRaw(Object? raw) => switch (raw) {
    'image' => MediaType.image,
    'video' => MediaType.video,
    'custom' => MediaType.custom,
    _ => MediaType.unknown,
  };
}

/// One playlist entry. A `custom` entry has no media of its own, only
/// [children] that are shown together.
class MediaItem {
  const MediaItem({
    required this.type,
    required this.url,
    this.children = const [],
    this.localPath,
  });

  final MediaType type;
  final String url;
  final List<MediaItem> children;

  /// Filled in once the download phase has resolved this entry.
  final String? localPath;

  bool get isDownloadable => url.isNotEmpty;

  bool get isReady => localPath != null;

  /// Flattens nested children out so the download phase can fetch the whole
  /// playlist in one batch.
  List<MediaItem> flattenDownloadable() => [
    if (isDownloadable) this,
    for (final child in children) ...child.flattenDownloadable(),
  ];

  MediaItem copyWith({String? localPath, List<MediaItem>? children}) {
    return MediaItem(
      type: type,
      url: url,
      children: children ?? this.children,
      localPath: localPath ?? this.localPath,
    );
  }

  @override
  String toString() =>
      'MediaItem(${type.name}, url: $url, children: ${children.length})';
}
