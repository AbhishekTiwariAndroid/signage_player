// All the durations the assignment specifies, kept in one place.

const Duration kItemDuration = Duration(seconds: 10);
const Duration kImageRotation = Duration(seconds: 5);

// extra time before the playback screen force-advances a view that never
// reported back
const Duration kAdvanceGrace = Duration(seconds: 3);

// last resort for an item whose length is not known up front, like a custom
// group waiting on its video
const Duration kUntimedItemCeiling = Duration(minutes: 2);

// how long a view stays black before giving up on media that failed to load
const Duration kFailedItemSkipDelay = Duration(seconds: 1);

const Duration kDownloadTimeout = Duration(seconds: 60);
const int kDownloadRetries = 1;
