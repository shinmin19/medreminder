import 'package:flutter/material.dart';

/// Minimal placeholder screen for iOS 27 testing
class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Medication List Screen - Placeholder',
        style: TextStyle(fontSize: 20),
      ),
    );
  }
}
