import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flame/input.dart'; // ← Para TapCallbacks

import 'package:frontend/modules/plant_game/mini_games/water/components/panel_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/text_water.dart';
import 'package:frontend/modules/plant_game/mini_games/water/components/water.dart';

// Importamos el servicio que maneja la lógica local (SharedPreferences)
import 'package:frontend/services/minigame_service.dart';

class WaterOverlay extends FlameGame {
  late ButtonResourceWater buttonWater;
  late TextWater textComponents; // Ahora instanciamos nuestra clase modificada
  
  final MinigameService _minigameService = MinigameService();

  // Variables de Estado del Minijuego
  double timeLeft = 5.0;
  int clickCount = 0;
  bool isGameActive = false;
  bool isGameOver = false;

  @override
  Future<void> onLoad() async {
    // 1. Instanciar los componentes
    textComponents = TextWater();
    buttonWater = ButtonResourceWater(onPressed: _onWaterTapped);

    // 2. Agregarlos al juego
    add(panelWater());
    add(buttonWater);
    add(textComponents);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    
    // Centrar el botón y los textos
    buttonWater
      ..position = canvasSize / 2
      ..anchor = Anchor.center;
      
    textComponents
      ..position = canvasSize / 2
      ..anchor = Anchor.center;
  }

  // Lógica al tocar la gota de agua
  void _onWaterTapped() {
    if (isGameOver) return; // Si ya terminó, ignorar clics

    if (!isGameActive) {
      isGameActive = true; // Inicia la cuenta regresiva en el primer toque
    }

    clickCount++;
    textComponents.updateClicks(clickCount); // Actualiza la pantalla
  }

  // Flame llama a update() en cada frame de la pantalla
  @override
  void update(double dt) {
    super.update(dt);

    if (isGameActive && !isGameOver) {
      timeLeft -= dt; // Restar el tiempo (dt = delta time en segundos)

      if (timeLeft <= 0) {
        timeLeft = 0;
        _endMinigame(); // Acabar el juego si el tiempo llega a 0
      }

      textComponents.updateTime(timeLeft); // Actualizar pantalla
    }
  }

  // Lógica de finalización
  Future<void> _endMinigame() async {
    isGameOver = true;
    isGameActive = false;
    buttonWater.state = 2; // Estado "Disabled" visualmente

    try {
      // 1. Guardar y procesar la recompensa en la base local
      final result = await _minigameService.playWaterMinigame(clickCount);
      
      // 2. Mostrar la alerta en pantalla
      _showAlert(result['message']);
      
    } catch (e) {
      print("Error al guardar recursos: $e");
    }
  }

  void _showAlert(String message) {
    // Agrega un componente de alerta nativo de Flame encima de todo
    final alertComponent = WaterAlertComponent(message: message, size: size);
    add(alertComponent);
  }
}

// -------------------------------------------------------------
// COMPONENTE DE ALERTA NATIVO (Se muestra al acabar el tiempo)
// -------------------------------------------------------------
class WaterAlertComponent extends PositionComponent {
  final String message;
  double _timeVisible = 0;
  static const double _autoCloseTime = 2.0;
  bool _closed = false;

  WaterAlertComponent({required this.message, required Vector2 size}) 
    : super(size: size);

  @override
  Future<void> onLoad() async {
    // Fondo oscuro semi-transparente (se puede tocar para cerrar)
    final background = RectangleComponent(
      size: size,
      paint: Paint()..color = Colors.black.withOpacity(0.7),
    );
    add(background);

    // Caja de diálogo central
    final dialogSize = Vector2(300, 150);
    final dialog = RectangleComponent(
      size: dialogSize,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFF1D899F),
    );
    add(dialog);

    // Texto de recompensa
    final text = TextComponent(
      text: message,
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 16, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    add(text);

    // Texto de ayuda
    final hint = TextComponent(
      text: 'Toca para cerrar',
      position: Vector2(size.x / 2, size.y / 2 + 50),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70, 
          fontSize: 12,
        ),
      ),
    );
    add(hint);
  }

  // Detecta cualquier toque en pantalla
  @override
  void onTapCancel() {
    _closeMinigame();
  }

  // Cierra automáticamente después de 2 segundos
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_closed) return;
    
    _timeVisible += dt;
    if (_timeVisible >= _autoCloseTime) {
      _closeMinigame();
    }
  }

  void _closeMinigame() {
    if (_closed) return;
    _closed = true;
    removeFromParent();
  }
}