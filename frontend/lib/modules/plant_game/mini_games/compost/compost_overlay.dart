
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/panel_compost.dart';

class CompostOverlay extends FlameGame {

  @override
  Future<void> onLoad() async {
    add(panelCompost());
    
  }
}

