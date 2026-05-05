import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/components/Animation_sun.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Button_resource_sun
//
// Botón para gastar Sol del inventario en la planta activa.
//   • Muestra la cantidad disponible en el inventario del usuario.
//   • Al pulsar: gasta 1 Sol → lanza animación → guarda .tree.
//   • Se actualiza automáticamente cuando PlantController notifica cambios.
// ─────────────────────────────────────────────────────────────────────────────
class Button_resource_sun extends SpriteButtonComponent with HasGameRef {
  final BuildContext context;

  late TextComponent _countText;

  Button_resource_sun({required this.context})
      : super(
          size: Vector2.zero(),
          button: null,
          buttonDown: null,
          onPressed: null,
        );

  @override
  Future<void> onLoad() async {
    button = await Sprite.load('Botones/Boton_RecursoSol_02.png');
    buttonDown = await Sprite.load('Botones/Boton_RecursoSol_01.png');
    size = button.srcSize / 2.3;

    // Contador de stock disponible
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

    // Suscribirse a cambios
    final controller = Provider.of<PlantController>(context, listen: false);
    controller.addListener(_onControllerChange);

    // Acción al pulsar
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
      return '${c.recursos.sol.cantidad}';
    } catch (_) {
      return '0';
    }
  }

  void _onControllerChange() {
    _countText.text = _stockText();
  }

  void _onTap() {
    final controller = Provider.of<PlantController>(context, listen: false);
    final success = controller.spendSun();
    if (!success) return; // sin stock — no hacer nada

    // Lanzar animación visual
    final anim = Animation_sun('pasto', Vector2(gameRef.size.x, gameRef.size.y))
      ..anchor = Anchor.center
      ..position = Vector2(gameRef.size.x / 2, gameRef.size.y / 2);
    gameRef.add(anim);

    // Persistir (SharedPreferences + export físico si tiene permiso)
    controller.saveTree();
  }
}
