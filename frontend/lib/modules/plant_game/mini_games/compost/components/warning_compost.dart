import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class warningCompost extends SpriteComponent with HasGameRef {

  final int compostAmount;
  warningCompost({required this.compostAmount});

  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Minijuegos/Panel_AvisoAgua_01.png');

    // Escalar proporcionalmente
     size = sprite!.srcSize/2;  


    final text = TextComponent(
      text: "Cantidad de compost obtenida:\n $compostAmount ", // ejemplo
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
