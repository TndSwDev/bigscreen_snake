import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _gridSize = 26;

class SnakePart {
  SnakePart(this.pos);

  final rect = RectangleComponent(paint: BasicPalette.black.paint());
  final Vector2 pos;

  void dispose() {
    rect.removeFromParent();
  }

  void updateSize(Vector2 boxSize, Vector2 boxOffset) {
    final size = boxSize.clone()..multiply(Vector2.all(1 / _gridSize));
    final position = size.clone()..multiply(pos);
    rect.size = size;
    rect.position = boxOffset + position;
  }
}

class Food {
  final Vector2 pos;
  SvgComponent? svg;

  Food(this.pos);

  Future<void> load() async {
    final glassesSVG = await Svg.load('images/glasses.svg');
    svg = SvgComponent(svg: glassesSVG);
  }

  void dispose() {
    svg?.removeFromParent();
  }

  void updateSize(Vector2 boxSize, Vector2 boxOffset) {
    final size = boxSize.clone()..multiply(Vector2.all(1 / _gridSize));
    final position = size.clone()..multiply(pos);
    svg?.size = size * 1.5;
    svg?.position = boxOffset + position - Vector2(size.x / 4, size.y / 4);
  }
}

class SnakeGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  SnakeGame();

  SvgComponent? background;
  RectangleComponent? box;
  var boxSize = Vector2(0, 0);
  var boxPosition = Vector2(0, 0);
  var directionH = 1;
  var directionV = 0;
  var snakeHeadX = _gridSize / 2;
  var snakeHeadY = _gridSize / 2;
  var timeFromStart = 0.0;
  var timeAtSnakeMove = 1.0;
  var stepWithoutFood = true;
  var speed = 0.4;
  final snakeParts = <SnakePart>[];
  Food? food;

  Future<void> addSnake(Vector2 pos) async {
    final part = SnakePart(pos);
    part.updateSize(boxSize, boxPosition);
    snakeParts.add(part);
    await add(part.rect);
  }

  @override
  Future<void> onLoad() async {
    final backgroundSVG = await Svg.load('images/snake-bg.svg');
    background = SvgComponent(svg: backgroundSVG, size: size);
    final paint = BasicPalette.black.paint() //
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    box = RectangleComponent(paint: paint);
    await add(background!);
    await add(box!);
    moveSnakeHead();
    moveSnakeHead();
    moveSnakeHead();
    moveSnakeHead();
    updateSizes(size);
    addFood();
    return super.onLoad();
  }

  @override
  void onRemove() {
    for (var part in snakeParts) {
      part.dispose();
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    timeFromStart += dt;
    if (timeAtSnakeMove < timeFromStart) {
      timeAtSnakeMove += speed;
      moveSnake();
    }
  }

  Future<void> addFood() async {
    var pos = snakeParts.first.pos;
    while (collideWithSelf(pos)) {
      pos = Vector2(
        Random().nextInt(_gridSize).toDouble(),
        Random().nextInt(_gridSize).toDouble(),
      );
    }
    food?.dispose();
    food = Food(pos);
    await food?.load();
    food?.updateSize(boxSize, boxPosition);
    add(food!.svg!);
    stepWithoutFood = false;
    if (speed > 0.15) {
      speed -= 0.025;
    }
  }

  Future<bool> moveSnakeHead() async {
    snakeHeadX += directionH;
    snakeHeadY += directionV;
    if (snakeHeadX < 0 || //
        snakeHeadX >= _gridSize ||
        snakeHeadY < 0 ||
        snakeHeadY >= _gridSize ||
        collideWithSelf(Vector2(snakeHeadX, snakeHeadY))) {
      gameOver();
      return false;
    } else {
      final pos = Vector2(snakeHeadX, snakeHeadY);
      await addSnake(pos);
      if (food != null && food!.pos == pos) {
        food!.dispose();
        await addFood();
      }
      return true;
    }
  }

  Future<void> moveSnake() async {
    if (await moveSnakeHead() && stepWithoutFood) {
      final tailpart = snakeParts.removeAt(0);
      tailpart.dispose();
    } else {
      stepWithoutFood = true;
    }
  }

  bool collideWithSelf(Vector2 pos) {
    for (var part in snakeParts) {
      if (pos == part.pos) return true;
    }
    return false;
  }

  void updateSizes(Vector2 size) {
    const aspectBackground = 900 / 579;
    const overallScale = 1.1;
    const scale = 0.65 * overallScale;
    final aspect = size.x / max(1, size.y);
    var h = 0.0;
    var w = 0.0;
    if (aspectBackground > aspect) {
      // background wider than window
      w = size.x;
      h = size.x / aspectBackground;
    } else {
      // window wider than background
      w = size.y * aspectBackground;
      h = size.y;
    }
    final x = (size.x - w) / 2;
    final y = (size.y - h) / 2;
    final xb = (size.x - h * scale) / 2;
    final yb = (size.y - h * scale) / 2;
    boxPosition = Vector2(xb, yb);
    boxSize = Vector2(h, h) * scale;
    box?.position = boxPosition;
    box?.size = boxSize;
    background?.size = Vector2(w, h) * overallScale;
    background?.position = Vector2(x, y) - Vector2(w, h) * (overallScale - 1) / 2;
    for (var part in snakeParts) {
      part.updateSize(boxSize, boxPosition);
    }
    food?.updateSize(boxSize, boxPosition);
  }

  @override
  KeyEventResult onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event.character == 'a') {
      directionH = -1;
      directionV = 0;
    } else if (event.character == 'd') {
      directionH = 1;
      directionV = 0;
    } else if (event.character == 'w') {
      directionH = 0;
      directionV = -1;
    } else if (event.character == 's') {
      directionH = 0;
      directionV = 1;
    }
    return KeyEventResult.handled;
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    updateSizes(canvasSize);
  }

  void gameOver() {
    pauseEngine();
  }
}
