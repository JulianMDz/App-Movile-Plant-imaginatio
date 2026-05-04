import 'package:flame/layout.dart';
import 'package:frontend/modules/plant_game/components/Animation_compost.dart';
import 'package:frontend/modules/plant_game/components/Animation_critical.dart';
import 'package:frontend/modules/plant_game/components/Animation_danger.dart';
import 'package:frontend/modules/plant_game/components/Animation_evo.dart';
import 'package:frontend/modules/plant_game/components/Animation_sun.dart';
import 'package:frontend/modules/plant_game/components/Animation_tombstone.dart';
import 'package:frontend/modules/plant_game/components/Animation_water.dart';
import 'package:frontend/modules/plant_game/components/Button_Inventary.dart';
import 'package:frontend/modules/plant_game/components/Button_game_3d.dart';
import 'package:frontend/modules/plant_game/components/Button_game_compost.dart';
import 'package:frontend/modules/plant_game/components/Button_game_sun.dart';
import 'package:frontend/modules/plant_game/components/Button_game_water.dart';
import 'package:frontend/modules/plant_game/components/Text_name.dart';
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

import 'package:frontend/modules/plant_game/plant_logic.dart';

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

    final panelBar = PanelLayout()
      ..anchor = Anchor.centerLeft
      ..position = Vector2(80, size.y/2); // columna centrada
  

    final sunGameButton = Button_sun_game(
      onPressed: () {
        add(SunOverlay(context: context));
      },
    );

    final waterGameButton = Button_water_game(
      onPressed: () {
        add(WaterOverlay(context: context));
      },
    );
    final compostGameButton = Button_compost_game(
      onPressed: () {
        add(CompostOverlay(context: context));
      },
    );

    final sunButton = Button_resource_sun(onPressed: () { });
    final waterButton = Button_resource_water(onPressed: () { });
    final compostButton = Button_resource_compost(onPressed: () { });

    final button3d = Button_game_3d(onPressed: () {
      overlays.add('sync');
    });
    final name = textName();
    
     final rowTop = RowComponent(
      children: [
        PaddingComponent(
              padding: EdgeInsets.only(right: 10),
              child: panelTitle,
            ),  
        PaddingComponent(
              padding: EdgeInsets.only(right: 30),
              child: panelInfo,
            ),   
        PaddingComponent(
              padding: EdgeInsets.only(right: 10),
              child: helpButton,
            ), 
        PaddingComponent(
              padding: EdgeInsets.only(right: 10),
              child: inventaryButton,
            ),
   
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..anchor = Anchor.topCenter
      ..position = Vector2(size.x/2, 30); // columna centrada
    add(rowTop);


    final layoutCenter = ColumnComponent(
      children: [
        sunGameButton,
        PaddingComponent(
          padding: EdgeInsets.only(top: 150),
          child: RowComponent(
            children: [
              PaddingComponent(
              padding: EdgeInsets.only(right: 200),
              child: waterGameButton,
            ),
              compostGameButton,
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        ),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..anchor = Anchor.center
      ..position = Vector2(size.x /2, size.y / 2+10);

    add(layoutCenter);

    final pastoSeed = PlantComponent(
    'pasto',
    Vector2(size.x/2, size.y/2 + 20),
    )
      ..anchor = Anchor.center;
    add(pastoSeed);

    add(panelBar);

    final columnRight = ColumnComponent(
      children: [
        PaddingComponent(
              padding: EdgeInsets.only(bottom: 20),
              child: sunButton,
            ),
        PaddingComponent(
              padding: EdgeInsets.only(bottom: 20),
              child: waterButton,
            ),
        compostButton,
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..size = Vector2(size.x*0.8, 80)
      ..anchor = Anchor.centerRight
      ..position = Vector2(size.x-20, size.y / 2);// fila arriba centrada
    add(columnRight);

    final rowDown = RowComponent(
      children: [
        PaddingComponent(
              padding: EdgeInsets.only(right: 400),
              child: name,
            ),
        button3d
      ],
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..anchor = Anchor.bottomCenter
      ..position = Vector2(size.x/2, size.y -10); // fila abajo centrada
    add(rowDown);
  }
}

