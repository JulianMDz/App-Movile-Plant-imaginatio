import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class textName extends TextComponent with HasGameRef {
  @override
  Future<void> onLoad() async {
    text = "Bienventid@, nombre";

    textRenderer = TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontFamily: 'Press Start 2P',
      ),
    );
  /// posición centrada en la parte inferior
  }
}