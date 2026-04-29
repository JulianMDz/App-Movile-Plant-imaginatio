import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class Button_compost_game extends SpriteButtonComponent {
  late TextComponent textComp;
  Button_compost_game({
    required void Function() onPressed,
  }) : super(
          size: Vector2.zero(),
          button: null,       // se inicializa luego
          buttonDown: null,   // se inicializa luego
          onPressed: onPressed,
        );

  @override
  Future<void> onLoad() async {
    // Cargar sprites aquí
    button = await Sprite.load('Botones/Boton_MinijuegoComposta_02.png');
    buttonDown = await Sprite.load('Botones/Boton_MinijuegoComposta_01.png');

    size = button.srcSize/3;  

    textComp = TextComponent(
      text: '1|10',
      textRenderer: TextPaint(
        style: const TextStyle(
          color:  Colors.white,
          fontSize: 9,
          fontFamily: 'Press Start 2P',
          fontWeight: FontWeight.bold,
        ),
        
      ),
    )
      ..anchor = Anchor.topCenter
      ..position = Vector2(size.x / 2, size.y + 5); 

    add(textComp);
  }
}
