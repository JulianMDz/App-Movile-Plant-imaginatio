class CompostLogic {
  double timeLeft = 3.0;

  int score = 4; // 🔥 empieza con 4
  int mistakes = 0;

  bool isGameActive = false;
  bool isGameOver = false;
  bool rewardProcessed = false;

  void start() {
    isGameActive = true;
  }

  void onCellTap(int row, int col, bool isCorrect) {
    if (isGameOver) return;

    if (!isCorrect) {
      mistakes++;

      score--; // ❌ pierde punto

      if (score < 0) score = 0;
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

  // 🎯 recompensa directa (0 a 4)
  int get compostReward => score;

  bool get shouldEndGame => isGameOver && !rewardProcessed;

  void markRewardProcessed() {
    rewardProcessed = true;
  }
}