import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/black_screen.dart';
import 'features/content/presentation/content_providers.dart';
import 'features/content/presentation/splash_screen.dart';
import 'features/playback/presentation/playback_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProviderScope(child: SignageApp()));
}

class SignageApp extends StatelessWidget {
  const SignageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Signage Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(surface: Colors.black),
      ),
      home: const _SignageHome(),
    );
  }
}

// Splash while the downloads run, playback once they are done. There is no
// navigation here, so the splash cannot disappear before the future settles.
class _SignageHome extends ConsumerWidget {
  const _SignageHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(preparedContentProvider)
        .when(
          loading: () => const SplashScreen(),
          error: (_, _) => const BlackScreen(),
          data: (playlist) =>
              playlist.isEmpty ? const BlackScreen() : const PlaybackScreen(),
        );
  }
}
