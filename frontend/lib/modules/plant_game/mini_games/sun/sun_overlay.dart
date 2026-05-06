import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart'; 


import 'package:frontend/modules/plant_game/mini_games/sun/components/panel_sun.dart';
import 'package:frontend/modules/plant_game/mini_games/sun/sun_logic.dart';
// Importamos el servicio que maneja la lógica local (SharedPreferences)
import 'package:frontend/services/minigame_service.dart';

class SunOverlay extends FlameGame {

  
  final MinigameService _minigameService = MinigameService();
  final SunLogic logic = SunLogic();

  @override
  Future<void> onLoad() async {
    final panel = PanelSun();
    panel.cambiarEstado(2);
    add(panel);
    logic.start();
  }

}

