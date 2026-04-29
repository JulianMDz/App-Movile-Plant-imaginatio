import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class LocalStorageService {
  static const String _usersKeyPrefix = "user_";
  
  // Equivale a _write_user en tu user_service.py
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_usersKeyPrefix${user.userId}', jsonEncode(user.toJson()));
  }

  // Equivale a _read_user en tu user_service.py
  Future<UserModel?> getUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('$_usersKeyPrefix$userId');
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  // Manejo de la sesión activa
  Future<void> saveCurrentSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_session_id', userId);
  }

  Future<String?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_session_id');
  }
}