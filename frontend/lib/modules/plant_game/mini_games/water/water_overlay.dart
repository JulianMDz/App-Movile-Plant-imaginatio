
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/panel_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/water.dart';

class WaterOverlay extends FlameGame {
  late ButtonResourceWater buttonWater;

  @override
  Future<void> onLoad() async {
    buttonWater = ButtonResourceWater(onPressed: () { });

    add(panelWater());
    add(buttonWater);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    buttonWater
      ..position = canvasSize / 2
      ..anchor = Anchor.center;
  }
}