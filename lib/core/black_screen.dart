import 'package:flutter/material.dart';

/// Fallback for every failure path. A signage screen should never show an
/// error message or a spinner, just black.
class BlackScreen extends StatelessWidget {
  const BlackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: SizedBox.expand(),
    );
  }
}
