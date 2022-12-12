import 'package:flutter/material.dart';
import 'package:snake/snake_page.dart';

void main() {
  runApp(const SnakeApp());
}

class SnakeApp extends StatelessWidget {
  const SnakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'SNAKE',
      home: Scaffold(
        body: SnakePage(),
      ),
    );
  }
}
