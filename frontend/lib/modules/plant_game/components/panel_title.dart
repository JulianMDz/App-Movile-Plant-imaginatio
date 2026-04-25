import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Panel_title extends SpriteComponent  {
   late TextComponent textComp;
  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Paneles/Panel_NombrePlanta_01.png');

    size = sprite!.srcSize/2;  
       


    textComp = TextComponent(
      text: 'Planta',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 12,
          fontFamily: 'Press Start 2P',
        ),
        
      ),
    )
      ..anchor = Anchor.center
      ..position = size / 2;

    add(textComp);
  }
}
