import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PanelEnter extends SpriteComponent  {
  late TextComponent textComp;
  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Paneles/Panel_Ayuda_04.png');

    size = sprite!.srcSize/1.6;  
       


    textComp = TextComponent(
      text: 'IMAGINATIO',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color.fromARGB(255, 152, 85, 47), 
          fontSize: 12,
          fontFamily: 'Press Start 2P',
        ),
        
      ),
    )
      ..anchor = Anchor.topCenter
      ..position = Vector2(size.x / 2, size.y / 2 - 70);

    add(textComp);
  }
}