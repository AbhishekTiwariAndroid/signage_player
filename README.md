# Digital Signage Player

Flutter app that downloads all media from the playlist first, then plays images
and videos in a fullscreen loop from local storage.

Order: Image 1 → Video 1 → Custom Group (video + 3 images at once) → repeat.

## How to run

Built with Flutter 3.44.4 / Dart 3.12.2.

```bash
flutter pub get
flutter run --release
```

Other commands:

```bash
flutter analyze
flutter build apk --release
```

Apk link download - https://loadly.io/SDegfOkW

First run needs internet to download the 6 media files. After that it works
offline.

Note: the first release build takes a few minutes because Gradle has to set up
the Android toolchain. Later builds are much faster.

## Folder structure

I used a feature-based clean architecture. There are two features, matching the
two phases of the app - `content` downloads the media, `playback` displays it.

```
lib/
  main.dart                            app entry, fullscreen setup, splash/playback switch
  core/
    constants.dart                     all durations (10s slot, 5s image rotation, timeouts)
    failures.dart                      DownloadFailure
    black_screen.dart                  black screen used as fallback everywhere
  features/
    content/
      domain/
        media_item.dart                MediaType enum + MediaItem model
        content_repository.dart        abstract interface
      data/
        content_json_source.dart       parses the playlist JSON
        media_cache_store.dart         file paths, manifest, cache check
        media_downloader.dart          downloads one file
        content_repository_impl.dart   runs all downloads in parallel
      presentation/
        content_providers.dart         Riverpod providers
        splash_screen.dart             black screen with the Flutter logo
    playback/
      domain/
        playback_sequencer.dart        which item is next and for how long
      presentation/
        playback_providers.dart        Riverpod providers
        playback_screen.dart           picks the right widget for the current item
        image_view.dart                one image for 10 seconds
        video_view.dart                one video for 10 seconds
        custom_group_view.dart         the 4 section layout with rotating images
```

Rules I followed:

- `playback` only imports from `content/domain`, never from `content/data`
- `content` never imports from `playback`
- `core` never imports from `features`
- Neither `domain` folder imports Flutter, so that logic is plain Dart and easy
  to test

I did not add usecase classes. In this project a usecase like `PrepareContent`
would just call `repository.prepareContent()` and nothing else, so the abstract
repository is already the boundary. Same reason for not making a separate DTO
class - the JSON source builds `MediaItem` directly.

## Some implementation details

**Downloads run in parallel** using `Future.wait` with `eagerError: false`, so
one broken URL does not cancel the others.

**Each file is downloaded only once.** A file counts as downloaded if
`manifest.json` has an entry for it AND the file exists on disk with size > 0.
File names are `sha1(url)` + the extension, so the same URL always maps to the
same file.

**Downloads are safe to interrupt.** The file is written as `something.part`
first and renamed only after it finishes. So if the app is killed mid-download,
there is no half-written file that looks complete. The manifest is written once
after all downloads finish, not after each one, because parallel writes would
corrupt it.

**Offline works** because playback only uses `Image.file()` and
`VideoPlayerController.file()`. There is no network code in the playback layer
at all.

**No PageView and no animations.** Content is swapped by changing the widget
key:

```dart
KeyedSubtree(
  key: ValueKey('$cycle:$index'),
  child: viewForItem,
)
```

When the key changes Flutter destroys the old widget and builds a new one. This
is also what disposes the old `VideoPlayerController` before the next one is
created.

**Disposal.** Every view cancels its timers, removes listeners and disposes the
controller in `dispose()`. There is also a `mounted` check after each `await` in
the video setup, because the widget can be removed while the video file is still
opening. In that case the controller is disposed right there instead.

**Riverpod** is used for state. A `FutureProvider` gives loading, error and data
as three built in states, so the download phase maps straight onto them and the
splash screen is just the loading one. `.when()` also forces all three to be
handled, so the error case cannot be forgotten. The splash stays visible until
every download finishes without needing a separate flag.

## Memory profiling with Flutter DevTools

I also checked memory in DevTools while the app was looping, since the loop runs
forever and a leaking video controller would eventually crash it. After around
25 cycles (~17 minutes) the view classes were still at 1 instance each
(`_CustomGroupViewState` 1, `_PlaybackScreenState` 1, `VideoSurface` 1) and the
Dart heap stayed flat at 12 MB across all readings. So the controllers and
timers are getting disposed and nothing builds up over long runs.

Run it with `flutter run --profile` and check the instance counts in DevTools if
you want to verify this.

## Assumptions

These were not clear in the PDF, so here is what I decided and why.

1. **Videos do not loop.** Point 4 says each item shows for exactly 10 seconds
   and point 5 says the video stops after 10 seconds. Looping is not mentioned
   anywhere. So the 5 second video plays once and stays on its last frame until
   the 10 seconds are over.

2. **Images in the custom group rotate between sections.** Every 5 seconds all
   three images shift by one position (A,B,C then B,C,A then C,A,B). For a 20
   second video that gives 4 rotations, which matches the example in the PDF.

3. **Images use `BoxFit.cover`.** The PDF says "fill the screen while
   maintaining aspect ratio". `cover` fills the screen and keeps the ratio by
   cropping a bit, while `contain` would leave black bars and not fill the
   screen.

4. **If a file fails to download it is skipped** and the rest of the playlist
   keeps playing. If a custom group's video fails, the whole group is skipped
   because the video controls the duration. Failed files are not saved in the
   manifest so they are tried again on the next launch.

5. **The playlist JSON is a constant in the code.** The PDF gives the JSON
   directly and no API URL, so there is nothing to fetch it from. If it needs to
   come from an API later, only `content_json_source.dart` has to change.

6. **Orientation is not locked.** Fullscreen immersive mode in both portrait and
   landscape.

7. **I changed the Android launch theme to black.** By default `flutter create`
   makes it white, so the app showed a white flash before the black splash
   screen appeared.

## Packages used

- `flutter_riverpod` - state management
- `video_player` - required by the assignment
- `http` - downloading files
- `path_provider` - app documents directory
- `path` - joining paths and getting file extensions
- `crypto` - sha1 for file names
