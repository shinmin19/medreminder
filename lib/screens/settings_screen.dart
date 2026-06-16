import 'package:flutter/material.dart';

/// Minimal placeholder screen for iOS 27 testing
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Settings Screen - Placeholder',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
