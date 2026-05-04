import '../models/models.dart';
import 'local_storage_service.dart';

/// Servicio de persistencia del archivo .tree.
///
/// Actúa como la capa de guardado del estado Flutter/Web. Solo serializa
/// campos que pertenecen al dominio de Flutter (recursos, fase, plantas).
/// Los datos de Unity (salud, xp, nivel) se preservan intactos porque
/// [LocalStorageService.saveUser] serializa el [UserModel] completo sin
/// modificar los campos que Unity escribe.
///
/// Uso desde un minijuego:
/// ```dart
/// final treeService = TreeStorageService();
/// await treeService.saveTreeLocally(user: controller.currentUser!);
/// ```
class TreeStorageService {
  final LocalStorageService _storage = LocalStorageService();

  /// Persiste el [user] completo en SharedPreferences como archivo .tree.
  ///
  /// Si se pasa [plants], reemplaza la lista de plantas del usuario antes de
  /// guardar (útil cuando el controller tiene cambios pendientes de merge).
  Future<void> saveTreeLocally({
    required UserModel user,
    List<PlantState>? plants,
    List<String>? seeds, // TODO: incorporar cuando UserModel tenga campo seeds
  }) async {
    if (plants != null) {
      user.plants = plants;
    }
    await _storage.saveUser(user);
  }
}
