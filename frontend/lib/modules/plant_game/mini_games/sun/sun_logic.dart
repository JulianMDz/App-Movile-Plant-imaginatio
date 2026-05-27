import 'dart:math';

/// Representa los cinco niveles de recompensa del minijuego del Sol.
/// El índice (1-5) coincide con el sprite de [PanelSun] (índices 0-4 con offset).
enum SunTier {
  bronce,    // Tier 1 → +1 sol
  plata,     // Tier 2 → +2 soles
  oro,       // Tier 3 → +3 soles
  diamante,  // Tier 4 → +4 soles
  solar,     // Tier 5 → +5 soles (máximo)
}

/// Extensión de utilidad sobre [SunTier].
extension SunTierX on SunTier {
  /// Recompensa en soles para este Tier.
  int get reward => index + 1; // bronce=1 … solar=5

  /// Nombre legible para mostrar en UI.
  String get label => name[0].toUpperCase() + name.substring(1);

  /// Índice del sprite en [PanelSun.spritesList] (offset +1 porque el índice 0
  /// es la pantalla de selección previa, no el panel de juego activo).
  int get spriteIndex => index + 1;

  /// Probabilidad (0.0–1.0) de SUBIR al siguiente Tier con el siguiente click.
  /// Escalera decreciente: es fácil saltar al inicio, difícil llegar a Solar.
  double get upgradeChance {
    switch (this) {
      case SunTier.bronce:   return 0.75; // 75 % de subir a Plata
      case SunTier.plata:    return 0.55; // 55 % de subir a Oro
      case SunTier.oro:      return 0.35; // 35 % de subir a Diamante
      case SunTier.diamante: return 0.20; // 20 % de subir a Solar
      case SunTier.solar:    return 0.00; // Ya en el tope, no puede subir más
    }
  }
}

/// Lógica pura y sin estado de UI del minijuego del Sol.
///
/// Reglas (del contexto del proyecto):
/// - Máximo **4 clicks** por partida.
/// - Cada click intenta subir el Tier actual con la probabilidad definida en
///   [SunTierX.upgradeChance].
/// - El juego termina cuando se alcanzan los 4 clicks o cuando el jugador
///   no puede subir más (Tier Solar).
/// - La recompensa final es [SunTier.reward] soles.
class SunLogic {
  static const int maxClicks = 4;

  final Random _rng;

  /// Tier actual del jugador. Empieza en Bronce.
  SunTier _currentTier = SunTier.bronce;

  /// Número de clicks realizados en la partida actual.
  int _clickCount = 0;

  /// Indica si el juego ya terminó (se procesó la recompensa).
  bool _gameOver = false;

  /// Flag que señala que [shouldEndGame] fue consumido y la recompensa debe
  /// procesarse exactamente una vez.
  bool _rewardProcessed = false;

  SunLogic({Random? random}) : _rng = random ?? Random();

  // ── Getters públicos ────────────────────────────────────────────────────────

  SunTier get currentTier => _currentTier;
  int get clickCount => _clickCount;
  bool get isGameOver => _gameOver;

  /// Número de soles que se otorgarán al terminar la partida.
  int get sunReward => _currentTier.reward;

  /// Índice del sprite que debe mostrar [PanelSun] para el Tier actual.
  int get currentSpriteIndex => _currentTier.spriteIndex;

  /// True en el primer frame en que el juego debe cerrarse.
  /// El overlay debe llamar a [markRewardProcessed] para consumir esta señal.
  bool get shouldEndGame => _gameOver && !_rewardProcessed;

  // ── Métodos públicos ────────────────────────────────────────────────────────

  /// Procesa un click del jugador. Retorna el [SunTier] resultante.
  ///
  /// - Incrementa el contador de clicks.
  /// - Intenta subir de Tier según la probabilidad del Tier actual.
  /// - Marca el juego como terminado si se alcanzaron [maxClicks] o se llegó
  ///   a [SunTier.solar].
  SunTier onTap() {
    if (_gameOver) return _currentTier;

    _clickCount++;

    // Intentar subir de Tier
    if (_currentTier != SunTier.solar) {
      final roll = _rng.nextDouble(); // 0.0 ≤ roll < 1.0
      if (roll < _currentTier.upgradeChance) {
        _currentTier = SunTier.values[_currentTier.index + 1];
      }
    }

    // Condición de fin: clicks agotados o Tier máximo alcanzado
    if (_clickCount >= maxClicks || _currentTier == SunTier.solar) {
      _gameOver = true;
    }

    return _currentTier;
  }

  /// Marca la recompensa como procesada para que [shouldEndGame] deje de
  /// emitir true. Debe llamarse desde el overlay inmediatamente después de
  /// otorgar los recursos.
  void markRewardProcessed() {
    _rewardProcessed = true;
  }

  /// Reinicia el estado completo para una nueva partida.
  void reset() {
    _currentTier = SunTier.bronce;
    _clickCount = 0;
    _gameOver = false;
    _rewardProcessed = false;
  }

  /// Devuelve un resumen legible del estado actual (útil para debugging).
  @override
  String toString() =>
      'SunLogic(tier: ${_currentTier.label}, clicks: $_clickCount/$maxClicks, '
      'reward: $sunReward, over: $_gameOver)';
}
