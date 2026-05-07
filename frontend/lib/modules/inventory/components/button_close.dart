import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/audio.dart';
import 'package:go_router/go_router.dart';

// -------------------------------------------------------
// Botón cerrar
// -------------------------------------------------------

// -------------------------------------------------------
// Botón cerrar — detiene música del inventario y navega
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
    AudioManager.click();
    AudioManager.stopMusica();
    GoRouter.of(context).go('/plant_game');
    event.continuePropagation = false;
  }
}