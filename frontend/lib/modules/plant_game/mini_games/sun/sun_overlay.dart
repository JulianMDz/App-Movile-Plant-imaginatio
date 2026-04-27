
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/plant_game/mini_games/sun/components/panel_sun.dart';

class SunOverlay extends FlameGame {

  @override
  Future<void> onLoad() async {
    add(panelSun());
    
  }
}

