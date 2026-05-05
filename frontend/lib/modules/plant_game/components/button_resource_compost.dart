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
          fontSize: 7,
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

  /// Muestra el progreso de composta hacia el siguiente fertilizante.
  /// Formato: "X/4" donde X = cantidad actual (0–3 residual).
  String _stockText() {
    try {
      final c = Provider.of<PlantController>(context, listen: false);
      final cantidad = c.recursos.composta.cantidad;
      // El inventario siempre guarda el residuo (0-3) tras la conversión.
      // Mostramos cuánto falta para completar el siguiente bloque de 4.
      return '${cantidad % 4}/4';
    } catch (_) {
      return '0/4';
    }
  }

  void _onControllerChange() {
    _countText.text = _stockText();
  }

  void _onTap() {
    final controller = Provider.of<PlantController>(context, listen: false);
    final success = controller.spendCompost();
    if (!success) return;

    final anim = Animation_compost('pasto', Vector2(gameRef.size.x, gameRef.size.y))
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    gameRef.add(anim);

    controller.saveTree();
  }
}
