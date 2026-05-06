import 'dart:math';
import '../models/models.dart';
import 'local_storage_service.dart';

class MinigameService {
  final LocalStorageService _storage = LocalStorageService();
  static const int compostToFertilizer = 4;
  final Random _random = Random();

  // MINIJUEGO DEL SOL: Basado en Tiers (1-5)
  Future<Map<String, dynamic>> playSunMinigame(int boxTier) async {
    if (boxTier < 1 || boxTier > 5) {
      throw Exception("El Tier de la caja debe estar entre 1 y 5");
    }

    // Calcula la recompensa según el Tier (puedes ajustar el multiplicador)
    int baseReward = boxTier * 2; 
    int randomBonus = _random.nextInt(boxTier); 
    int totalReward = baseReward + randomBonus;

    // Actualiza los recursos del usuario activo
    final userId = await _storage.getCurrentSession();
    if (userId != null) {
      final user = await _storage.getUser(userId);
      if (user != null) {
        user.resources.sunAmount += totalReward;
        await _storage.saveUser(user);
      }
    }

    return {
      "success": true,
      "reward": totalReward,
      "message": "¡Caja Tier $boxTier abierta! Obtuviste $totalReward sol"
    };
  }

  // MINIJUEGO DE AGUA
  Future<Map<String, dynamic>> playWaterMinigame(int clicks) async {
    int reward = 0;
    if (clicks >= 50) { reward = 6; }
    else if (clicks >= 35) { reward = 4; }
    else if (clicks >= 25) { reward = 2; }

    final userId = await _storage.getCurrentSession();
    if (userId != null) {
      final user = await _storage.getUser(userId);
      if (user != null) {
        user.resources.waterAmount += reward;
        await _storage.saveUser(user);
      }
    }

    return {"success": true, "reward": reward, "message": "Obtuviste $reward agua"};
  }

  // MINIJUEGO DE COMPOSTA
  Future<Map<String, dynamic>> playCompostMinigame(int compostCollected, int trashClicked) async {
    int valid = (compostCollected - trashClicked).clamp(0, 9999).toInt();
    
    int fertilizerGained = 0;
    int remainingCompost = 0;

    final userId = await _storage.getCurrentSession();
    if (userId != null) {
      final user = await _storage.getUser(userId);
      if (user != null) {
        int totalCompost = user.resources.compostAmount + valid;
        
        fertilizerGained = totalCompost ~/ compostToFertilizer;
        remainingCompost = totalCompost % compostToFertilizer;

        user.resources.compostAmount = remainingCompost;
        user.resources.fertilizerAmount += fertilizerGained;
        
        await _storage.saveUser(user);
      }
    }

    return {
      "success": true,
      "fertilizerGained": fertilizerGained,
      "compostAdded": valid,
      "message": fertilizerGained > 0 
          ? "¡Convertiste composta en $fertilizerGained fertilizante(s)!" 
          : "Obtuviste $valid composta"
    };
  }
}