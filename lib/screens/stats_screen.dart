import 'package:flutter/material.dart';

/// Minimal placeholder screen for iOS 27 testing
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Stats Screen - Placeholder',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
