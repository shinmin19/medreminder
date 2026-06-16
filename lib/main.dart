import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '用药提醒',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const Scaffold(
        appBar: AppBar(title: Text('用药提醒')),
        body: Center(
          child: Text(
            'App加载中...',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
