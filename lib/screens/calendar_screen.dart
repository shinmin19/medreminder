import 'package:flutter/material.dart';

/// Minimal placeholder screen for iOS 27 testing
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Calendar Screen - Placeholder',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
