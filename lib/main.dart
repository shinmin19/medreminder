import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print('=== Flutter started ===');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test',
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.red,
          child: const Center(
            child: Text(
              'Flutter OK!',
              style: TextStyle(color: Colors.white, fontSize: 48),
            ),
          ),
        ),
      ),
    );
  }
}
