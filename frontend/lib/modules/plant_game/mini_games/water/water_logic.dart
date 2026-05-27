class WaterLogic {
  double timeLeft = 5.0;
  int clickCount = 0;
  bool isGameActive = false;
  bool isGameOver = false;
  bool rewardProcessed = false;


  void start() {
  isGameActive = true;
  }

  void onTap() {
    if (isGameOver) return;

    clickCount++;
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

  int targetClicks = 50;

  int get waterReward {
    final half = targetClicks / 2;

    if (clickCount < half) {
      return 0;
    } else if (clickCount == half) {
      return 2;
    } else if (clickCount < targetClicks) {
      return 4;
    } else {
      return 6;
    }
  }
  bool get shouldEndGame => isGameOver && !rewardProcessed;

  void markRewardProcessed() {
    rewardProcessed = true;
  }
}