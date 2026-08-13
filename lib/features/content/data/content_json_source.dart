import 'dart:convert';

import '../domain/media_item.dart';

// The assignment gives this JSON inline and no API url, so it is a constant.
// Only this class would change if it had to come from a network call.
const String _playlistJson = '''
{
  "result": [
    {
      "type": "image",
      "url": "https://images.pexels.com/photos/32417863/pexels-photo-32417863.jpeg",
      "custom": []
    },
    {
      "type": "video",
      "url": "https://samplelib.com/mp4/sample-5s-360p.mp4",
      "custom": []
    },
    {
      "type": "custom",
      "url": "",
      "custom": [
        {
          "type": "video",
          "url": "https://samplelib.com/mp4/sample-20s-360p.mp4"
        },
        {
          "type": "image",
          "url": "https://images.pexels.com/photos/38667897/pexels-photo-38667897.jpeg"
        },
        {
          "type": "image",
          "url": "https://images.pexels.com/photos/38058187/pexels-photo-38058187.jpeg"
        },
        {
          "type": "image",
          "url": "https://images.pexels.com/photos/35461871/pexels-photo-35461871.jpeg"
        }
      ]
    }
  ]
}
''';

class ContentJsonSource {
  const ContentJsonSource();

  /// Empty list if the JSON is broken. A signage display has nobody around to
  /// act on a crash, so bad content just means nothing to play.
  List<MediaItem> read() {
    try {
      final decoded = jsonDecode(_playlistJson);
      if (decoded is! Map) return const [];

      final result = decoded['result'];
      if (result is! List) return const [];

      return _toItemList(result);
    } on FormatException {
      return const [];
    }
  }

  // entries that are not objects are skipped instead of crashing
  List<MediaItem> _toItemList(List<dynamic> entries) {
    final items = <MediaItem>[];
    for (final entry in entries) {
      if (entry is Map<String, dynamic>) {
        items.add(_toItem(entry));
      }
    }
    return items;
  }

  MediaItem _toItem(Map<String, dynamic> json) {
    var children = <MediaItem>[];

    // a custom group has nested items, so build those the same way
    final nested = json['custom'];
    if (nested is List) {
      children = _toItemList(nested);
    }

    return MediaItem(
      type: MediaType.fromRaw(json['type']),
      url: json['url'] as String? ?? '',
      children: children,
    );
  }
}
