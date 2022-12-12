import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:snake/snake_game.dart';

class SnakePage extends StatefulWidget {
  const SnakePage({super.key});

  @override
  State<SnakePage> createState() => _SnakePageState();
}

class _SnakePageState extends State<SnakePage> {
  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: SnakeGame(),
    );
  }
}
