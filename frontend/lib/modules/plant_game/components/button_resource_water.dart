import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/components/Animation_water.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Button_resource_water
//
// Botón para gastar Agua del inventario en la planta activa.
// ─────────────────────────────────────────────────────────────────────────────
class Button_resource_water extends SpriteButtonComponent with HasGameRef {
  final BuildContext context;

  late TextComponent _countText;

  Button_resource_water({required this.context})
      : super(
          size: Vector2.zero(),
          button: null,
          buttonDown: null,
          onPressed: null,
        );

  @override
  Future<void> onLoad() async {
    button = await Sprite.load('Botones/Boton_RecursoAgua_02.png');
    buttonDown = await Sprite.load('Botones/Boton_RecursoAgua_01.png');
    size = button.srcSize / 2.3;

    _countText = TextComponent(
      text: _stockText(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontFamily: 'Press Start 2P',
        ),
      ),
    )
      ..anchor = Anchor.topLeft
      ..position = Vector2(2, 6);
    add(_countText);

    final controller = Provider.of<PlantController>(context, listen: false);
    controller.addListener(_onControllerChange);

    onPressed = _onTap;
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
      return '${c.recursos.agua.cantidad}';
    } catch (_) {
      return '0';
    }
  }

  void _onControllerChange() {
    _countText.text = _stockText();
  }

  void _onTap() {
    final controller = Provider.of<PlantController>(context, listen: false);
    final success = controller.spendWater();
    if (!success) return;

    final anim = Animation_water('pasto', Vector2(gameRef.size.x, gameRef.size.y))
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    gameRef.add(anim);

    controller.saveTree();
  }
}
