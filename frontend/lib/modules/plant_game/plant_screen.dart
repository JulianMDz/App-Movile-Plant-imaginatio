import 'dart:convert';

import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
import 'package:flutter/services.dart';
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


import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

class PlantGameScreen extends FlameGame {
  final BuildContext context;

  late PanelLayout _panelBar;
  late RowComponent _rowTop;
  late ColumnComponent _layoutCenter;
  late PlantComponent _plant;
  late ColumnComponent _columnRight;
  late RowComponent _rowDown;

  bool _isLayoutReady = false;
  String _lastPlantType = ''; // Para detectar cambios de planta activa
  int _lastPlantStage = 2;

  PlantGameScreen(this.context);

  @override
  Future<void> onLoad() async {
    // NO pre-cargar imágenes - cargar bajo demanda cuando se seleccione una planta
    // Esto evita el problema de assets no encontrados al inicio

    // Cargar datos del .tree al iniciar y esperar para usar la planta real
    final controller = Provider.of<PlantController>(context, listen: false);
    await controller.loadCurrentTree();

    // Listener para animaciones de evolución y muerte
    controller.addListener(_onControllerAnimationChange);

    add(Background());
    final helpButton = Button_help(onPressed: () { });
    final panelTitle = Panel_title();
    final inventaryButton = Button_inventory(onPressed: () { 
      GoRouter.of(context).go('/inventory');
      },
    );
    
    final panelInfo = Panel_resource_info();

    _panelBar = PanelLayout(context: context)
      ..anchor = Anchor.centerLeft
      ..position = Vector2(8 + size.x * 0.05, size.y / 2);

    // Obtener controller para verificar cooldowns
    final controller = Provider.of<PlantController>(context, listen: false);

    final sunGameButton = Button_sun_game(
      onPressed: () {
        if (!controller.canPlaySunGame()) {
          final remaining = controller.getSunGameRemainingCooldown();
          final timeStr = controller.formatRemainingCooldown(remaining);
          _showCooldownMessage('Sol', timeStr);
          return;
        }
        add(SunOverlay(context: context));
      },
    );

    final waterGameButton = Button_water_game(
      onPressed: () {
        if (!controller.canPlayWaterGame()) {
          final remaining = controller.getWaterGameRemainingCooldown();
          final timeStr = controller.formatRemainingCooldown(remaining);
          _showCooldownMessage('Agua', timeStr);
          return;
        }
        add(WaterOverlay(context: context));
      },
    );
    final compostGameButton = Button_compost_game(
      context: context,
      onPressed: () {
        if (!controller.canPlayCompostGame()) {
          final remaining = controller.getCompostGameRemainingCooldown();
          final timeStr = controller.formatRemainingCooldown(remaining);
          _showCooldownMessage('Composta', timeStr);
          return;
        }
        add(CompostOverlay(context: context));
      },
    );

    final sunButton = Button_resource_sun(context: context);
    final waterButton = Button_resource_water(context: context);
    final compostButton = Button_resource_compost(context: context);

    final button3d = Button_game_3d(onPressed: () {
      overlays.add('sync');
    });
    final name = textName(context: context);
    
    _rowTop = RowComponent(
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
    add(_rowTop);


    _layoutCenter = ColumnComponent(
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

    add(_layoutCenter);

    add(_panelBar);

    String pType = 'Pasto';
    int pStage = 2; // bush
    if (controller.activePlant != null) {
      pType = controller.activePlant!.id;
      final fase = controller.activePlant!.estado.fase;
      if (fase == 'semilla') pStage = 1;
      else if (fase == 'arbusto') pStage = 2;
      else if (fase == 'planta') pStage = 3;
      else if (fase == 'ent') pStage = 4;
    }

    _plant = PlantComponent(
      pType,
      pStage,
      Vector2(size.x / 2, size.y / 2),
    )
    ..anchor = Anchor.center;
    add(_plant);


    _columnRight = ColumnComponent(
      children: [
        PaddingComponent(
              padding: EdgeInsets.only(bottom: 12),
              child: sunButton,
            ),
        PaddingComponent(
              padding: EdgeInsets.only(bottom: 12),
              child: waterButton,
            ),
        compostButton,
      ],
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..anchor = Anchor.centerRight
      ..position = Vector2(size.x - 8, size.y / 2);
    add(_columnRight);

    _rowDown = RowComponent(
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
    add(_rowDown);

    _isLayoutReady = true;
    _applyLayout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_isLayoutReady) {
      _applyLayout(size);
    }
  }

  void _applyLayout(Vector2 size) {
      _panelBar.position = Vector2(8 + size.x * 0.05, size.y / 2);
      _rowTop.position = Vector2(size.x / 2, 30);
      _layoutCenter.position = Vector2(size.x / 2, size.y / 2 + 10);
      
      // La altura base de referencia para cálculos de posición (ej. 1080p landscape)
      final double scaleFactor = size.y / 1080.0;
      
      // Aplicar estrictamente la escala original de la fase (sin modificar)
      _plant.scale = _plant.stageScale; 
      
// Posicionar en el 78% de la pantalla (suelo) + el offset visual de la fase escalado
      _plant.position = Vector2(
        size.x / 2, 
        size.y / 2 + (_plant.stageOffset.y * scaleFactor),
      );
      
      _columnRight.position = Vector2(size.x - 8, size.y * 0.48);
      _rowDown.position = Vector2(size.x / 2, size.y - 10);
  }

  void _onControllerAnimationChange() {
    try {
      if (context == null) return;
      final controller = Provider.of<PlantController>(context, listen: false);
    final plantType = controller.activePlant?.id ?? 'pasto';
    
    // Detectar cambio de planta activa y cargar bajo demanda
    if (plantType != _lastPlantType) {
      _lastPlantType = plantType;
      
      // Determinar la fase
      final fase = controller.activePlant?.estado.fase ?? 'arbusto';
      int newStage = 2;
      if (fase == 'semilla') newStage = 1;
      else if (fase == 'planta') newStage = 3;
      else if (fase == 'ent') newStage = 4;
      
      // Cargar bajo demanda las imágenes de la nueva planta
      _plant.updatePlant(plantType, newStage);
      debugPrint('[PlantScreen] 🔄 Planta cambiada a: $plantType (fase: $fase)');
    }

    if (controller.showEvolutionAnimation) {
      final anim = Animation_evolution(
        plantType,
        Vector2(size.x / 2, size.y / 2),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = true;
      add(anim);
      controller.clearAnimationFlags();
      debugPrint('[PlantScreen] 🌱 Animación de evolución reproducida');
    }

    if (controller.showDeathAnimation) {
      final anim = Animation_tombstone(
        plantType,
        Vector2(size.x / 2, size.y / 2),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = true;
      add(anim);
      controller.clearAnimationFlags();
      debugPrint('[PlantScreen] 💀 Animación de muerte reproducida');
    }

    if (controller.showCriticalAnimation) {
      final anim = Animation_critical(
        plantType,
        Vector2(size.x / 2, size.y * 0.3),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = true;
      add(anim);
      controller.clearAnimationFlags();
    }

    if (controller.showDangerAnimation) {
      final anim = Animation_danger(
        plantType,
        Vector2(size.x / 2, size.y * 0.3),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = true;
      add(anim);
      controller.clearAnimationFlags();
      }
    } catch (e) {
      // Silenciar errores de contexto - el widget se está disposeando
    }
  }

  void _showCooldownMessage(String gameName, String remainingTime) {
    debugPrint('[$gameName Game] En cooldown - tiempo restante: $remainingTime');
    // TODO: Mostrar snackbar visual en Flutter
    // Por ahora solo debug log - se puede agregar UI después
  }
}

