import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Panel_resource_info extends SpriteComponent  {
     late TextComponent textComp;
  @override
  Future<void> onLoad() async {
    // Cargar la imagen
    sprite = await Sprite.load('Paneles/Panel_AvisoPlanta_01.png');

    size = sprite!.srcSize/2.5;    

    textComp = TextComponent(
      text: 'Necestio algo',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 10,
          fontFamily: 'Press Start 2P',
        ),
        
      ),
    )
      ..anchor = Anchor.center
      ..position = size / 2;

    add(textComp);
  }
}
