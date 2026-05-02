
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/panel_compost.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/components/text_compost.dart';

class CompostOverlay extends FlameGame {
  late CompostGrid compostGrid;

  @override
  Future<void> onLoad() async {
    compostGrid = CompostGrid();
    add(panelCompost());
    add(compostGrid);
    add(textCompost()); 
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    compostGrid
      ..anchor = Anchor.center
      ..position = Vector2(canvasSize.x / 2, canvasSize.y / 2+20);
  }
}

