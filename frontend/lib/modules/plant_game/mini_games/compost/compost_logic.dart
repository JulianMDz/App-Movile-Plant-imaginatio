// ─────────────────────────────────────────────────────────────────────────────
// CompostLogic — Lógica del minijuego de Composta
//
// Reglas del juego:
//   • El grid tiene 4 orgánicos y 4 inorgánicos (8 celdas en total).
//   • El jugador debe tocar SOLO los orgánicos antes de que se acabe el tiempo.
//   • Cada orgánico tocado:  +1 punto (max 4).
//   • Cada inorgánico tocado: -1 punto (mínimo 0).
//   • Tiempo límite: 5 segundos.
//
// Recompensa final:
//   • compostReward = puntos acumulados (0 a 4).
//   • La conversión 4 composta → 1 fertilizante ocurre en el overlay,
//     ya que requiere acceso al inventario global del PlantController.
// ─────────────────────────────────────────────────────────────────────────────
class CompostLogic {
  double timeLeft = 5.0;

  /// Puntos acumulados (orgánicos tocados - inorgánicos tocados).
  int score = 0;

  /// Número de errores (inorgánicos tocados).
  int mistakes = 0;

  bool isGameActive = false;
  bool isGameOver = false;
  bool rewardProcessed = false;

  void start() {
    isGameActive = true;
  }

  /// Llamado por el grid cuando el usuario toca una celda.
  /// [isCorrect] = true → orgánico ✅  |  false → inorgánico ❌
  void onCellTap(int row, int col, bool isCorrect) {
    if (!isGameActive || isGameOver) return;

    if (isCorrect) {
      // Orgánico tocado: suma punto (máximo 4)
      score = (score + 1).clamp(0, 4);
    } else {
      // Inorgánico tocado: resta punto y cuenta error
      mistakes++;
      score = (score - 1).clamp(0, 4);
    }
  }

  void update(double dt) {
    if (isGameActive && !isGameOver) {
      timeLeft -= dt;

      if (timeLeft <= 0) {
        timeLeft = 0;
        isGameOver = true;
        isGameActive = false;
      }
    }
  }

  /// Puntos finales (0 a 4) — cada uno equivale a 1 unidad de composta.
  int get compostReward => score;

  bool get shouldEndGame => isGameOver && !rewardProcessed;

  void markRewardProcessed() {
    rewardProcessed = true;
  }
}