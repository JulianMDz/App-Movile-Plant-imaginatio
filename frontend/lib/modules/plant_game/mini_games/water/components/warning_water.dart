import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class warningWater extends SpriteComponent with HasGameRef {

  final int waterAmount;
  warningWater({required this.waterAmount});

  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Minijuegos/Panel_AvisoAgua_01.png');

    // Escalar proporcionalmente
     size = sprite!.srcSize/2;  


    final text = TextComponent(
      text: "Cantidad de agua obtenida:\n $waterAmount ", // ejemplo
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontFamily: 'Press Start 2P',
        ),
      ),
    )
      ..anchor = Anchor.center
      ..position = Vector2(size.x / 2, size.y / 2); // 🔥 esquina superior derecha

    add(text);
  }
}
