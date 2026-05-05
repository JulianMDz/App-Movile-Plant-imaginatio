import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/components/Animation_compost.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Button_resource_compost
//
// Botón para gastar Composta del inventario en la planta activa.
// ─────────────────────────────────────────────────────────────────────────────
class Button_resource_compost extends SpriteButtonComponent with HasGameRef {
  final BuildContext context;

  late TextComponent _countText;

  Button_resource_compost({required this.context})
      : super(
          size: Vector2.zero(),
          button: null,
          buttonDown: null,
          onPressed: null,
        );

  @override
  Future<void> onLoad() async {
    button = await Sprite.load('Botones/Boton_RecursoAbono_02.png');
    buttonDown = await Sprite.load('Botones/Boton_RecursoAbono_01.png');
    size = button.srcSize / 2.3;

    _countText = TextComponent(
      text: _stockText(),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontFamily: 'Press Start 2P',
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
    )
      ..anchor = Anchor.topLeft
      ..position = Vector2(2, 2);
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

  /// Muestra la cantidad entera de fertilizante disponible.
  /// 4 puntos de composta = 1 fertilizante.
  String _stockText() {
    try {
      final c = Provider.of<PlantController>(context, listen: false);
      final cantidad = c.recursos.composta.cantidad;
      return '${cantidad ~/ 4}';
    } catch (_) {
      return '0';
    }
  }

  void _onControllerChange() {
    _countText.text = _stockText();
  }

  void _onTap() {
    final controller = Provider.of<PlantController>(context, listen: false);
    // Gastar 1 fertilizante requiere consumir 4 puntos de composta
    final success = controller.spendCompost(amount: 4);
    if (!success) return;

    final anim = Animation_compost('pasto', Vector2(gameRef.size.x, gameRef.size.y))
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    gameRef.add(anim);

    controller.saveTree();
  }
}
