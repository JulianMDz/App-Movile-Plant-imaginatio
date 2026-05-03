import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart'; // ← Para TapCallbacks


import 'package:frontend/modules/plant_game/mini_games/compost/components/compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/panel_compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/text_compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/warning_compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/compost_logic.dart';
// Importamos el servicio que maneja la lógica local (SharedPreferences)
import 'package:frontend/services/minigame_service.dart';

class CompostOverlay extends FlameGame {
  late CompostGrid compostGrid;
  late textCompost textComponents;

  final MinigameService _minigameService = MinigameService();
  final CompostLogic logic = CompostLogic();
  

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
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    compostGrid
      ..position = canvasSize / 2
      ..anchor = Anchor.center;

    textComponents
      ..position = canvasSize / 2
      ..anchor = Anchor.center;
  
  }

  void _onCompostTapped(int row, int col, bool isCorrect) {
  logic.onCellTap(row, col, isCorrect);
}

  @override
  void update(double dt) {
    super.update(dt);

    logic.update(dt);

    textComponents.updateTime(logic.timeLeft);

    if (logic.shouldEndGame) {
      logic.markRewardProcessed();
      _endMinigame();
    }
  }

  Future<void> _endMinigame() async {
    compostGrid.state = 2;

    try {
      final result =
          await _minigameService.playCompostMinigame(logic.compostReward, logic.mistakes);

      _showAlert(result['message']);
    } catch (e) {
      print("Error al guardar recursos: $e");
    }
  }

  void _closeOverlay() {
      removeFromParent();
    }

    void _showAlert(String message) {
      add(
        CompostAlertComponent
        (message: message,
        size: size,
        onClose: _closeOverlay,
        compostAmount: logic.compostReward,
        )
      );
    }
  }



// -------------------------------------------------------------
// ALERTA FINAL
// -------------------------------------------------------------
class CompostAlertComponent extends PositionComponent with TapCallbacks {
  final String message;
  final VoidCallback onClose;
  final int compostAmount;
  bool _closed = false;

  CompostAlertComponent({
    required this.message,
    required Vector2 size,
    required this.onClose,
    required this.compostAmount,
  }) : super(size: size);

  @override
  Future<void> onLoad() async {
    // 👇 aquí sí funciona
    final compostA = warningCompost(compostAmount: compostAmount);

    // opcional: centrarlo
    compostA
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;

    add(compostA);
  }


  @override
  void onTapDown(TapDownEvent event) {
    _closeMinigame();
  }

  @override
  void update(double dt) {
    super.update(dt);
  }

  void _closeMinigame() {
    if (_closed) return;
    _closed = true;
    onClose(); 
    removeFromParent();
  }
  
}

