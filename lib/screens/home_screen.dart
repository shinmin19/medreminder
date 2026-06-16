import 'package:flutter/material.dart';

/// Minimal placeholder screen for iOS 27 testing
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home Screen - Placeholder',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
