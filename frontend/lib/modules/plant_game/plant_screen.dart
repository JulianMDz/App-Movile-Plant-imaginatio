import 'dart:convert';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/modules/plant_game/components/Animation_compost.dart';
import 'package:frontend/modules/plant_game/components/Animation_critical.dart';
import 'package:frontend/modules/plant_game/components/Animation_danger.dart';
import 'package:frontend/modules/plant_game/components/Animation_evo.dart';
import 'package:frontend/modules/plant_game/components/Animation_sun.dart';
import 'package:frontend/modules/plant_game/components/Animation_tombstone.dart';
import 'package:frontend/modules/plant_game/components/Animation_water.dart';
import 'package:frontend/modules/plant_game/components/Button_Inventary.dart';
import 'package:frontend/modules/plant_game/components/Button_audio.dart';
import 'package:frontend/modules/plant_game/components/Button_credit.dart';
import 'package:frontend/modules/plant_game/components/Button_game_3d.dart';
import 'package:frontend/modules/plant_game/components/Button_game_compost.dart';
import 'package:frontend/modules/plant_game/components/Button_game_sun.dart';
import 'package:frontend/modules/plant_game/components/Button_game_water.dart';
import 'package:frontend/modules/plant_game/components/Button_profile.dart';
import 'package:frontend/modules/plant_game/components/Text_name.dart';
import 'package:frontend/modules/plant_game/components/button_resource_compost.dart';
import 'package:frontend/modules/plant_game/components/button_resource_sun.dart';
import 'package:frontend/modules/plant_game/components/button_resource_water.dart';
import 'package:frontend/modules/plant_game/components/cooldown_indicator.dart';
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
import 'package:frontend/core/audio.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:frontend/modules/plant_game/plant_controller.dart';

class PlantGameScreen extends FlameGame {
  final BuildContext context;

  late PanelLayout _panelBar;
  late RowComponent _rowTop;
  late Panel_title _panelTitle;
  late Panel_resource_info _panelInfo;
  late ColumnComponent _layoutCenter;
  late PlantComponent _plant;
  late ColumnComponent _columnRight;
  late RowComponent _rowDown;

  bool _isLayoutReady = false;
  String _lastPlantType = ''; // Para detectar cambios de planta activa
  int _lastPlantStage = 2;
  String _lastPlantFase = ''; // Para detectar cambios de fase (evolución)

  PlantGameScreen(this.context);
   @override
  Color backgroundColor() => const Color.fromARGB(255, 61, 67, 17);

  @override
  Future<void> onLoad() async {
    // NO pre-cargar imágenes - cargar bajo demanda cuando se seleccione una planta
    // Esto evita el problema de assets no encontrados al inicio

    // Cargar datos del .tree al iniciar y esperar para usar la planta real
    final controller = Provider.of<PlantController>(context, listen: false);
    await controller.loadCurrentTree();

    // Listener para animaciones de evolución y muerte
    controller.addListener(_onControllerAnimationChange);

    // Música principal al abrir la pantalla
    await AudioManager.musicaPrincipal();

    add(Background());

    // Botón de debug para avanzar tiempo (solo visible en modo debug)
    final debugTimeButton = _DebugTimeButton(
      gameRef: this,
      onAdvance: (minutes) async {
        final controller = Provider.of<PlantController>(context, listen: false);
        await controller.debugAdvanceTime(minutes);
      },
    )..priority = 100;
    add(debugTimeButton);

    final helpButton = Button_help(onPressed: () { });

    String pType = 'Pasto';

    _panelTitle = Panel_title(pType.toUpperCase());

    final inventaryButton = Button_inventory(
      onPressed: () {
        // Detiene principal antes de ir al inventario
        AudioManager.stopMusica();
        GoRouter.of(context).go('/inventory');
      },
    );
    final creditButton = Button_credit(onPressed: () { });
    final profileButton = Button_profile(onPressed: () {AudioManager.click();});
    final buttonAudio = Button_audio(onPressed: () {
      AudioManager.toggleMute();
    });


    _panelInfo = Panel_resource_info('Estado normal');

    _panelBar = PanelLayout(context: context)
      ..anchor = Anchor.centerLeft
      ..position = Vector2(80, size.y / 2);

    final sunGameButton = Button_sun_game(
      onPressed: () {
        AudioManager.recolectarSoles();
        AudioManager.miniGames();
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
        AudioManager.recolectarAgua();
        AudioManager.miniGames();
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
        AudioManager.recolectarComposta();
        AudioManager.miniGames();
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

    // Botón para 3D — click general
    final button3d = Button_game_3d(
      onPressed: () {
      overlays.add('sync');
   
        AudioManager.click();
      },
    );

    final name = textName(context: context);

    _rowTop = RowComponent(
      children: [
        
        PaddingComponent(
          padding: EdgeInsets.only(right: 10),
          child: creditButton,
        ),
        PaddingComponent(
          padding: EdgeInsets.only(right: 10),
          child: _panelTitle,
        ),
        PaddingComponent(
          padding: EdgeInsets.only(right: 30),
          child: _panelInfo,
        ),
        PaddingComponent(
          padding: EdgeInsets.only(right: 10),
          child: helpButton,
        ),
        PaddingComponent(
          padding: EdgeInsets.only(right: 10),
          child: inventaryButton,
        ),
        PaddingComponent(
          padding: EdgeInsets.only(right: 10),
          child: inventaryButton,
        ),
        buttonAudio,
      ],
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
    )
      ..anchor = Anchor.topCenter
      ..position = Vector2(size.x / 2, 30);
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

    // Indicadores de cooldown sobre los botones de minijuego
    final sunCooldown = CooldownIndicator(
      context: context,
      gameType: 'sun',
      position: Vector2(size.x / 2, size.y / 2 - 60),
    );
    add(sunCooldown);

    final waterCooldown = CooldownIndicator(
      context: context,
      gameType: 'water',
      position: Vector2(size.x / 2 - 80, size.y / 2 + 90),
    );
    add(waterCooldown);

    final compostCooldown = CooldownIndicator(
      context: context,
      gameType: 'compost',
      position: Vector2(size.x / 2 + 80, size.y / 2 + 90),
    );
    add(compostCooldown);

    add(_panelBar);
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
      Vector2(size.x, size.y),
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
      ..size = Vector2(size.x * 0.8, 80)
      ..anchor = Anchor.centerRight
      ..position = Vector2(size.x , size.y / 2);
    add(_columnRight);

    _rowDown = RowComponent(
      children: [
        PaddingComponent(
          padding: EdgeInsets.only(right: 10),
          child: profileButton,
        ),
        PaddingComponent(
          padding: EdgeInsets.only(right: 400),
          child: name,
        ),
        button3d,
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
      _panelBar.position = Vector2(50 + size.x * 0.05, size.y / 2);
      _rowTop.position = Vector2(size.x / 2, 30);
      _layoutCenter.position = Vector2(size.x / 2, size.y / 2 + 10);
      
      // La altura base de referencia para cálculos de posición (ej. 1080p landscape)
      final double scaleFactor = size.y / 1080.0;
      
      // Aplicar estrictamente la escala original de la fase (sin modificar)
      // La escala se actualiza en _onControllerAnimationChange según el estado 
      
// Posicionar en el 78% de la pantalla (suelo) + el offset visual de la fase escalado
      _plant.position = Vector2(
        size.x / 2, 
        size.y / 2 + (_plant.stageOffset.y * scaleFactor),
      );
      
      _columnRight.position = Vector2(size.x -70, size.y * 0.48);
      _rowDown.position = Vector2(size.x / 2, size.y - 10);
  }

  void _onControllerAnimationChange() {
    debugPrint('[PlantScreen] 🔔 _onControllerAnimationChange ejecutado (notifyListeners llamado)');
    try {
      if (context == null) return;
      final controller = Provider.of<PlantController>(context, listen: false);
    final plant = controller.activePlant;
    final plantType = plant?.id ?? 'pasto';
    final fase = plant?.estado.fase ?? 'arbusto';
    final sol = plant?.recursosAplicados.sol ?? 0;
    final agua = plant?.recursosAplicados.agua ?? 0;
    final fert = plant?.recursosAplicados.fertilizante ?? 0;
    String statusMessage = 'Estado normal';

      // MUERTO
      if (fase == 'muerto' || sol <= 0 || agua <= 0) {
        statusMessage = 'La planta murio';
      }

      // CRITICO
      else if (sol <= 2 || agua <= 2) {
        statusMessage = 'Estado critico';
      }

      // PELIGRO
      else if (sol <= 4 || agua <= 4) {
        statusMessage = 'Necesita recursos';
      }

      // FERTILIZANTE BAJO
      else if (fert <= 1) {
        statusMessage = 'Necesita composta';
      }

      // PERFECTO
      else if (sol >= 8 && agua >= 8 && fert >= 5) {
        statusMessage = 'La planta esta feliz';
      }

      _panelInfo.setMessage(statusMessage);



    debugPrint('[PlantScreen] 📊 Estado actual: planta=$plantType, fase=$fase, sol=$sol, agua=$agua, fert=$fert');

    // Bug 3: Debug adicional para verificar fase al cargar
    if (fase == 'muerto') {
      debugPrint('[PlantScreen] 💀 La planta está en estado de MUERTE');
    }

    // Bug 1: Reducir escala un 5% cuando la planta está en estado de muerte
    if (fase == 'muerto') {
      _plant.scale = _plant.stageScale * 0.95;
      debugPrint('[PlantScreen] 💀 Planta en muerte - escala reducida 5%');
    } else {
      _plant.scale = _plant.stageScale;
    }
    
    // Detectar cambio de planta activa O cambio de fase (evolución/muerte)
    if (plantType != _lastPlantType || fase != _lastPlantFase) {
      _lastPlantType = plantType;
      _lastPlantFase = fase;
      _panelTitle.setTitle(plantType.toUpperCase());
      
      // Determinar el stage según la fase
      int newStage = 2;
      if (fase == 'semilla') newStage = 1;
      else if (fase == 'planta') newStage = 3;
      else if (fase == 'ent') newStage = 4;
      
      // Cargar bajo demanda las imágenes de la nueva planta
      _plant.updatePlant(plantType, newStage);
      debugPrint('[PlantScreen] 🔄 Planta cambiada a: $plantType (fase: $fase, stage: $newStage)');
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

    // Bug 2: Eliminar animaciones de estado anteriores antes de agregar nuevas
    final existingStateAnims = children.where((c) => 
      c is Animation_critical || c is Animation_danger || c is Animation_tombstone
    ).toList();
    for (final anim in existingStateAnims) {
      anim.removeFromParent();
    }
    debugPrint('[PlantScreen] 🗑️ Eliminadas ${existingStateAnims.length} animaciones de estado anteriores');

    // Bug 2: Lógica de prioridad - solo mostrar la animación correspondiente al estado actual
    // PRIORIDAD 1: MUERTO (sol <= 0 O agua <= 0 O fase == 'muerto')
    if (fase == 'muerto' || sol <= 0 || agua <= 0) {
      final anim = Animation_tombstone(
        plantType,
        Vector2(size.x / 2, size.y / 2+70),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = false; // Se mantiene siempre en muerte
      add(anim);
      controller.clearAnimationFlags();
      debugPrint('[PlantScreen] 💀 Animación de MUERTE mostrada (fase=$fase, sol=$sol, agua=$agua)');
    }
    // PRIORIDAD 2: CRÍTICO (sol <= 2 O agua <= 2)
    else if (sol <= 2 || agua <= 2) {
      final anim = Animation_critical(
        plantType,
        Vector2(size.x / 2, size.y * 0.3),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = true;
      add(anim);
      controller.clearAnimationFlags();
      debugPrint('[PlantScreen] ⚠️ Animación de CRÍTICO mostrada (sol=$sol, agua=$agua)');
    }
    // PRIORIDAD 3: PELIGRO (sol <= 4 O agua <= 4, pero no crítico)
    else if (sol <= 4 || agua <= 4) {
      final anim = Animation_danger(
        plantType,
        Vector2(size.x / 2, size.y * 0.3),
      )
        ..anchor = Anchor.center
        ..removeOnFinish = true;
      add(anim);
      controller.clearAnimationFlags();
      debugPrint('[PlantScreen] ⚠️ Animación de PELIGRO mostrada (sol=$sol, agua=$agua)');
    }
    // Estado normal: no hay animación (recursos OK)
    else {
      debugPrint('[PlantScreen] ✅ Estado normal - sin animación (sol=$sol, agua=$agua)');
    }

    controller.clearAnimationFlags();
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

// ─────────────────────────────────────────────────────────────────────────────
// Botón de debug para avanzar el tiempo (solo visible en modo debug)
// ─────────────────────────────────────────────────────────────────────────────
class _DebugTimeButton extends PositionComponent with TapCallbacks {
  final FlameGame gameRef;
  final Function(int minutes) onAdvance;
  
  _DebugTimeButton({required this.gameRef, required this.onAdvance});

  @override
  Future<void> onLoad() async {
    position = Vector2(gameRef.size.x - 50, 50);
    size = Vector2(40, 40);
  }

  @override
  void render(Canvas canvas) {
    // Dibujar botón de debug: círculo rojo semitransparente con "T"
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      Paint()..color = const Color(0x80FF0000),
    );
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'T',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Avanza 10 minutos + aplica decay + actualiza cooldowns
    onAdvance(10);
    debugPrint('[Debug] ⏱️ Tiempo avanzado 10 minutos por botón debug');
    event.continuePropagation = false;
  }

}

