import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/modules/plant_game/mini_games/compost/components/compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/panel_compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/text_compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/compost_logic.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';
import 'package:frontend/services/tree_storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CompostOverlay — Flame overlay del minijuego de Composta
//
// Patrón unificado con SunOverlay y WaterOverlay:
//   1. Recibe [BuildContext] por constructor para acceder a PlantController.
//   2. Al terminar, llama controller.addCompost() → TreeStorageService.saveTreeLocally()
//      (Regla de Oro: auto-sync inmediato del archivo .tree).
// ─────────────────────────────────────────────────────────────────────────────
class CompostOverlay extends FlameGame {
  final BuildContext context;

  late CompostGrid compostGrid;
  late textCompost textComponents;

  final CompostLogic logic = CompostLogic();
  final TreeStorageService _treeService = TreeStorageService();

  bool _gameEndHandled = false;

  CompostOverlay({required this.context});

  // ── Ciclo de vida ──────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    textComponents = textCompost();
    compostGrid = CompostGrid(onCellTap: _onCompostTapped);

    add(panelCompost());
    add(compostGrid);
    add(textComponents);

    logic.start();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    compostGrid
      ..position = size / 2
      ..anchor = Anchor.center;
    textComponents
      ..position = size / 2
      ..anchor = Anchor.center;
  }

  // ── Input ──────────────────────────────────────────────────────────────────

  void _onCompostTapped(int row, int col, bool isCorrect) {
    logic.onCellTap(row, col, isCorrect);
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
    compostGrid.state = 2;
    final reward = logic.compostReward;

    // ① Actualizar inventario en memoria via PlantController (Provider)
    try {
      final controller = Provider.of<PlantController>(context, listen: false);
      controller.addCompost(reward);

      // ② Auto-sync inmediato del archivo .tree (Regla de Oro del proyecto)
      if (controller.currentTree != null) {
        await _treeService.saveTreeLocally(flutterData: controller.currentTree!);
      }
    } catch (e) {
      debugPrint('[CompostOverlay] Error en auto-sync .tree: $e');
    }

    // ③ Mostrar alerta de resultado (sprite existente del equipo)
    _showAlert(reward);
  }

  void _showAlert(int reward) {
    add(
      CompostAlertComponent(
        size: size,
        onClose: _closeOverlay,
        compostAmount: reward,
      ),
    );
  }

  void _closeOverlay() => removeFromParent();
}

// ─────────────────────────────────────────────────────────────────────────────
// CompostAlertComponent — Pantalla de resultado final.
// Muestra overlay unificado. Tap en cualquier parte cierra.
// ─────────────────────────────────────────────────────────────────────────────
class CompostAlertComponent extends PositionComponent with TapCallbacks {
  final VoidCallback onClose;
  final int compostAmount;
  bool _closed = false;

  CompostAlertComponent({
    required Vector2 size,
    required this.onClose,
    required this.compostAmount,
  }) : super(size: size);

  @override
  Future<void> onLoad() async {
    // Fondo semitransparente
    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xCC000000),
      ),
    );

    // Texto principal de resultado
    add(
      TextComponent(
        text: '🌱 Composta obtenida\n+$compostAmount Unidad${compostAmount != 1 ? 'es' : ''}',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xFF66FF66), // Verde claro
            fontSize: 26,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 8, color: Colors.black)],
          ),
        ),
        anchor: Anchor.center,
        position: size / 2 - Vector2(0, 20),
      ),
    );

    // Instrucción de cierre
    add(
      TextComponent(
        text: 'Toca para continuar',
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xAAFFFFFF),
            fontSize: 14,
          ),
        ),
        anchor: Anchor.center,
        position: size / 2 + Vector2(0, 30),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_closed) return;
    _closed = true;
    onClose();
    removeFromParent();
  }
}
