import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/mini_games/water/components/panel_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/text_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/warning_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/water_logic.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';
import 'package:frontend/services/tree_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WaterOverlay — Flame overlay del minijuego del Agua
//
// Patrón unificado con SunOverlay:
//   1. Recibe [BuildContext] por constructor para acceder a PlantController.
//   2. Al terminar, llama controller.addWater() → TreeStorageService.saveTreeLocally()
//      (Regla de Oro: auto-sync inmediato del archivo .tree).
// ─────────────────────────────────────────────────────────────────────────────
class WaterOverlay extends FlameGame {
  final BuildContext context;

  late ButtonResourceWater buttonWater;
  late TextWater textComponents;

  final WaterLogic logic = WaterLogic();
  final TreeStorageService _treeService = TreeStorageService();

  bool _gameEndHandled = false;

  WaterOverlay({required this.context});

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    textComponents = TextWater();
    buttonWater = ButtonResourceWater(onPressed: _onWaterTapped);

    add(panelWater());
    add(buttonWater);
    add(textComponents);

    logic.start();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    buttonWater
      ..position = size / 2
      ..anchor = Anchor.center;
    textComponents
      ..position = size / 2
      ..anchor = Anchor.center;
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void _onWaterTapped() {
    logic.onTap();
    textComponents.updateClicks(logic.clickCount);
  }

  // ── Game loop ──────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    logic.update(dt);
    textComponents.updateTime(logic.timeLeft);

    if (logic.shouldEndGame && !_gameEndHandled) {
      logic.markRewardProcessed();
      _gameEndHandled = true;
      _endMinigame();
    }
  }

  // ── Recompensa y cierre ────────────────────────────────────────────────────

  Future<void> _endMinigame() async {
    buttonWater.state = 2;
    final reward = logic.waterReward;

    // ① Actualizar inventario en memoria via PlantController (Provider)
    try {
      final controller = Provider.of<PlantController>(context, listen: false);
      controller.addWater(reward);

      // ② Auto-sync inmediato del archivo .tree (Regla de Oro del proyecto)
      if (controller.currentTree != null) {
        await _treeService.saveTreeLocally(flutterData: controller.currentTree!);
      }
    } catch (e) {
      debugPrint('[WaterOverlay] Error en auto-sync .tree: $e');
    }

    // ③ Mostrar alerta de resultado (sprite existente del equipo)
    _showAlert(reward);
  }

  void _showAlert(int reward) {
    add(
      WaterAlertComponent(
        size: size,
        onClose: _closeOverlay,
        waterAmount: reward,
      ),
    );
  }

  void _closeOverlay() => removeFromParent();
}

// ─────────────────────────────────────────────────────────────────────────────
// WaterAlertComponent — Pantalla de resultado final.
// Muestra el sprite warningWater existente. Tap en cualquier parte cierra.
// ─────────────────────────────────────────────────────────────────────────────
class WaterAlertComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onClose;
  final int waterAmount;
  bool _closed = false;

  WaterAlertComponent({
    required Vector2 size,
    required this.onClose,
    required this.waterAmount,
  }) : super(size: size);

  @override
  Future<void> onLoad() async {
    final waterA = warningWater(waterAmount: waterAmount);
    waterA
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;
    add(waterA);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_closed) return;
    _closed = true;
    onClose();
    removeFromParent();
  }
}