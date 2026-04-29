import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class textName extends TextBoxComponent with HasGameRef {
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
    
    anchor = Anchor.bottomCenter;
    align = Anchor.center; //
    position = Vector2(gameRef.size.x/2 , gameRef.size.y-30); // posición centrada en la parte inferior
  }
}