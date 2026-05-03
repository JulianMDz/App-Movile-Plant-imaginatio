import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart'; // ← Para TapCallbacks

import 'package:frontend/modules/plant_game/mini_games/water/components/panel_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/text_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/warning_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/water_logic.dart';
// Importamos el servicio que maneja la lógica local (SharedPreferences)
import 'package:frontend/services/minigame_service.dart';

class WaterOverlay extends FlameGame {
  late ButtonResourceWater buttonWater;
  late TextWater textComponents;

  final MinigameService _minigameService = MinigameService();
  final WaterLogic logic = WaterLogic();

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
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    buttonWater
      ..position = canvasSize / 2
      ..anchor = Anchor.center;

    textComponents
      ..position = canvasSize / 2
      ..anchor = Anchor.center;
  }

  void _onWaterTapped() {
    logic.onTap();
    textComponents.updateClicks(logic.clickCount);
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
    buttonWater.state = 2;

    try {
      final result =
          await _minigameService.playWaterMinigame(logic.clickCount);

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
      WaterAlertComponent
      (message: message,
       size: size,
       onClose: _closeOverlay,
       waterAmount: logic.waterReward,
      )
    );
  }
}

// -------------------------------------------------------------
// ALERTA FINAL
// -------------------------------------------------------------
class WaterAlertComponent extends PositionComponent with TapCallbacks {
  final String message;
  final VoidCallback onClose;
  final int waterAmount;
  bool _closed = false;

  WaterAlertComponent({
    required this.message,
    required Vector2 size,
    required this.onClose,
    required this.waterAmount,
  }) : super(size: size);

  @override
  Future<void> onLoad() async {
    // 👇 aquí sí funciona
    final waterA = warningWater(waterAmount: waterAmount);

    // opcional: centrarlo
    waterA
      ..position = Vector2(size.x / 2, size.y / 2)
      ..anchor = Anchor.center;

    add(waterA);
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