
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

// -------------------------------------------------------
// Botón con imagen
// -------------------------------------------------------

class ImageButton extends PositionComponent with TapCallbacks {
  final String label;
  final VoidCallback onTap;
  final Vector2 btnSize;
  final FlameGame gameRef;

  ImageButton({
    required this.label,
    required Vector2 position,
    required this.btnSize,
    required this.gameRef,
    required this.onTap,
  }) {
    this.position = position;
    size = btnSize;
  }

  @override
  Future<void> onLoad() async {
    add(SpriteComponent()
      ..sprite = Sprite(gameRef.images.fromCache('Botones/Boton_General_01a.png'))
      ..size = btnSize);

    add(TextComponent(
      text: label,
      anchor: Anchor.center,
      position: btnSize / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 9,
          fontFamily: 'Press Start 2P',
          color: Color(0xFFFFFFFF),
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    onTap();
    event.continuePropagation = false;
  }
}

