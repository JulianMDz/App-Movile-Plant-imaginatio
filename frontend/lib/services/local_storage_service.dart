import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String _usersKeyPrefix = 'user_';
  static const String _cooldownKeyPrefix = 'cooldown_';
  
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_usersKeyPrefix${user.userId}', jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_usersKeyPrefix$userId');
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  Future<void> saveCurrentSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_session_id', userId);
  }

  Future<String?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_session_id');
  }

  Future<void> saveMinigameCooldown(String userId, String minigameType, DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_cooldownKeyPrefix${userId}_', time.toIso8601String());
  }

  Future<DateTime?> getMinigameCooldown(String userId, String minigameType) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_cooldownKeyPrefix${userId}_');
    if (data == null) return null;
    return DateTime.parse(data);
  }

  Future<void> addResource(String userId, String resourceType, int amount) async {
    final user = await getUser(userId);
    if (user == null) return;
    
    switch (resourceType) {
      case 'sun':
        user.resources.sunAmount += amount;
        break;
      case 'water':
        user.resources.waterAmount += amount;
        break;
      case 'fertilizer':
        user.resources.fertilizerAmount += amount;
        break;
      case 'compost':
        user.resources.compostAmount += amount;
        break;
    }
    await saveUser(user);
  }

  Future<bool> useResource(String userId, String resourceType, int amount) async {
    final user = await getUser(userId);
    if (user == null) return false;
    
    switch (resourceType) {
      case 'sun':
        if (user.resources.sunAmount < amount) return false;
        user.resources.sunAmount -= amount;
        break;
      case 'water':
        if (user.resources.waterAmount < amount) return false;
        user.resources.waterAmount -= amount;
        break;
      case 'fertilizer':
        if (user.resources.fertilizerAmount < amount) return false;
        user.resources.fertilizerAmount -= amount;
        break;
      case 'compost':
        if (user.resources.compostAmount < amount) return false;
        user.resources.compostAmount -= amount;
        break;
      default:
        return false;
    }
    await saveUser(user);
    return true;
  }
}
