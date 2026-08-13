import 'package:flutter/material.dart';

/// Shown while the downloads run. Just the logo, no progress bar.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: FlutterLogo(size: 128)),
    );
  }
}
