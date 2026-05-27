import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/plant_controller.dart';

class Button_compost_game extends SpriteButtonComponent {
  final BuildContext context;
  late TextComponent textComp;

  Button_compost_game({
    required this.context,
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

    size = button.srcSize / 3;

    textComp = TextComponent(
      text: _stockText(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontFamily: 'Press Start 2P',
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )
      ..anchor = Anchor.topCenter
      ..position = Vector2(size.x / 2, size.y + 5);

    add(textComp);

    // Suscribirse a cambios en los recursos
    final controller = Provider.of<PlantController>(context, listen: false);
    controller.addListener(_onControllerChange);
  }

  @override
  void onRemove() {
    try {
      Provider.of<PlantController>(context, listen: false)
          .removeListener(_onControllerChange);
    } catch (_) {}
    super.onRemove();
  }

  String _stockText() {
    try {
      final c = Provider.of<PlantController>(context, listen: false);
      final cantidad = c.recursos.composta.cantidad;
      return '${cantidad % 4}/4';
    } catch (_) {
      return '0/4';
    }
  }

  void _onControllerChange() {
    textComp.text = _stockText();
  }
}
