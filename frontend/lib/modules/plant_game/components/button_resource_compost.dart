import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:frontend/modules/plant_game/components/Animation_compost.dart';

class Button_resource_compost extends SpriteButtonComponent with HasGameRef {
  Button_resource_compost({
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
    button = await Sprite.load('Botones/Boton_RecursoAbono_02.png');
    buttonDown = await Sprite.load('Botones/Boton_RecursoAbono_01.png');

    size = button.srcSize/2.3;  

  onPressed = () { 
    final animacionCompost = Animation_compost(
      'pasto',
      Vector2(gameRef.size.x, gameRef.size.y),
    )
      ..anchor = Anchor.center
      ..position = Vector2(
        gameRef.size.x / 2,
        gameRef.size.y / 2,
      );
    gameRef.add(animacionCompost);
  };

    final text = TextComponent(
      text: "40", // ejemplo
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontFamily: 'Press Start 2P',
        ),
      ),
    )
      ..anchor = Anchor.topLeft
      ..position = Vector2(2, 6); // 🔥 esquina superior derecha

    add(text);
  
  }
}
