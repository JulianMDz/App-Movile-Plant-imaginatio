import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'local_storage_service.dart';

class AuthService {
  final LocalStorageService _storage = LocalStorageService();
  final Uuid _uuid = const Uuid();

  Future<UserModel> register(String username) async {
    final userId = _uuid.v4();
    final newUser = UserModel(
      userId: userId,
      username: username,
      unlockedPlants: ['pasto'], // Planta por defecto según tu python
      plants: [],
      resources: UserResources(),
    );
    
    await _storage.saveUser(newUser);
    await _storage.saveCurrentSession(userId);
    return newUser;
  }

  Future<UserModel> login(String userId) async {
    final user = await _storage.getUser(userId);
    if (user == null) throw Exception("Usuario no encontrado");
    await _storage.saveCurrentSession(userId);
    return user;
  }
}