import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// -------------------------------------------------------
// Botón cerrar
// -------------------------------------------------------

class CloseButtonComponent extends SpriteComponent with TapCallbacks {
  final BuildContext context;
  CloseButtonComponent(this.context);

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load('Botones/Boton_Cerrar_01.png');
  }

  @override
  void onTapDown(TapDownEvent event) {
    GoRouter.of(context).go('/plant_game');
    event.continuePropagation = false;
  }
}