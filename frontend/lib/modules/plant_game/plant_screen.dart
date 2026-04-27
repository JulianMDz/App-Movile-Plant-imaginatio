import 'package:flame/layout.dart';
import 'package:frontend/modules/plant_game/components/Button_Inventary.dart';
import 'package:frontend/modules/plant_game/components/Button_game_compost.dart';
import 'package:frontend/modules/plant_game/components/Button_game_sun.dart';
import 'package:frontend/modules/plant_game/components/Button_game_water.dart';
import 'package:frontend/modules/plant_game/components/button_resource_compost.dart';
import 'package:frontend/modules/plant_game/components/button_resource_sun.dart';
import 'package:frontend/modules/plant_game/components/button_resource_water.dart';
import 'package:frontend/modules/plant_game/components/panel_bar.dart';
import 'package:frontend/modules/plant_game/components/panel_resource.dart';
import 'package:frontend/modules/plant_game/components/panel_title.dart';
import 'package:frontend/modules/plant_game/components/plant.dart';
import 'package:frontend/modules/plant_game/components/background.dart';
import 'package:frontend/modules/plant_game/components/Button_help.dart';
import 'package:flame/components.dart';
import 'package:go_router/go_router.dart';

import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/modules/plant_game/mini_games/compost/compost_overlay.dart';
import 'package:frontend/modules/plant_game/mini_games/sun/sun_overlay.dart';
import 'package:frontend/modules/plant_game/mini_games/water/water_overlay.dart';


class PlantGameScreen extends FlameGame {
  final BuildContext context;

  PlantGameScreen(this.context);

  @override
  Future<void> onLoad() async {
    add(Background());
    final helpButton = Button_help(onPressed: () { });
    final panelTitle = Panel_title();
    final inventaryButton = Button_inventory(onPressed: () { 
      GoRouter.of(context).go('/inventory');
      },
    );
    
    final panelInfo = Panel_resource_info();

    final panelBar = PanelLayout();

    final sunGameButton = Button_sun_game(
      onPressed: () {
          add(SunOverlay());
       })
    ..anchor = Anchor.centerLeft
    ..position = Vector2(20, 150);

    final waterGameButton = Button_water_game(
      onPressed: () {
        add(WaterOverlay());
      },
    );
    final compostGameButton = Button_compost_game(
      onPressed: () {
        add(CompostOverlay());
      });

    final sunButton = Button_resource_sun(onPressed: () { });
    final waterButton = Button_resource_water(onPressed: () { });
    final compostButton = Button_resource_compost(onPressed: () { });
    
    final layout = ColumnComponent(
      children: [
        RowComponent(
          children: [
            PaddingComponent(
              padding: EdgeInsets.only(right: 10),
              child: helpButton,
            ),
            PaddingComponent(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: panelTitle,
            ),
            PaddingComponent(
              padding: EdgeInsets.only(left: 10),
              child: inventaryButton,
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
        )
          ..size = Vector2(size.x*0.8, 80)
          ..anchor = Anchor.topCenter
          ..position = Vector2(size.x / 2, 30), // fila arriba centrada
        RowComponent(
          children: [panelInfo],
        )
          ..anchor = Anchor.topCenter
          ..position = Vector2(size.x / 2, 80), // fila arriba centrada
      ]
    );
    add(layout);

    add(sunGameButton);

    final columnCenter = ColumnComponent(
      children: [
        panelBar,
        PaddingComponent(
              padding: EdgeInsets.only(top: 80),
              child: waterGameButton,
            ),
            
        PaddingComponent(
              padding: EdgeInsets.only(top: 50),
              child: compostGameButton,
            ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..anchor = Anchor.centerRight
      ..position = Vector2(size.x-20, size.y /2-40); // columna centrada
    add(columnCenter);

    final pastoSeed = PlantComponent(
    'pasto',
    Vector2(size.x/2, 220),
    )
      ..anchor = Anchor.center;
    add(pastoSeed);


    final rowDown = RowComponent(
      children: [
        PaddingComponent(
              padding: EdgeInsets.only(right: 40),
              child: sunButton,
            ),
        PaddingComponent(
              padding: EdgeInsets.only(right: 40),
              child: waterButton,
            ),
        compostButton,
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..size = Vector2(size.x*0.8, 80)
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x / 2, size.y - 40); // fila arriba centrada
    add(rowDown);

   
  }
}

