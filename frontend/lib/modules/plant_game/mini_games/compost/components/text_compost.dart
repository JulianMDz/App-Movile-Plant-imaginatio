import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class textCompost extends TextBoxComponent with HasGameRef {
  @override
  Future<void> onLoad() async {
    text = "2 SEC";

    textRenderer = TextPaint(
      style: const TextStyle(
        color: Color.fromARGB(255, 152, 85, 47),
        fontSize: 20,
        fontFamily: 'Press Start 2P',
      ),
    );
    
    anchor = Anchor.center;
    align = Anchor.center; //
    position = Vector2(gameRef.size.x / 2, 120);
  }
}