import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../../services/local_storage_service.dart';

/// Controlador de estado global del juego de plantas.
///
/// Gestiona el [UserModel] activo en memoria y expone métodos para
/// modificar únicamente los campos del dominio Flutter/Web, respetando
/// la Matriz de Responsabilidades del archivo .tree:
///   🟢 Flutter escribe: recursos (sol, agua, composta, abono), fase de planta.
///   🔴 Unity escribe  : salud, xp, nivel — PlantController NUNCA toca estos.
class PlantController extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  UserModel? _currentUser;

  // ── Getters públicos ────────────────────────────────────────────────────────

  /// Usuario activo. Puede ser null antes de llamar a [loadCurrentUser].
  UserModel? get currentUser => _currentUser;

  /// Lista de plantas del usuario activo (vacía si no hay usuario cargado).
  List<PlantState> get plants => _currentUser?.plants ?? [];

  /// Recursos actuales del usuario (valores en 0 si no hay usuario cargado).
  UserResources get resources =>
      _currentUser?.resources ?? UserResources();

  /// Semillas disponibles.
  /// TODO: agregar campo `seeds` a UserModel cuando se migre al formato .tree v3.
  List<String> get seeds => [];

  // ── Carga de sesión ─────────────────────────────────────────────────────────

  /// Lee el userId de la sesión activa y carga su [UserModel] desde
  /// SharedPreferences. Llama a este método al iniciar la pantalla del juego.
  Future<void> loadCurrentUser() async {
    try {
      final userId = await _storage.getCurrentSession();
      if (userId == null) return;
      _currentUser = await _storage.getUser(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('[PlantController] Error al cargar usuario: $e');
    }
  }

  // ── Métodos de recursos (dominio Flutter/Web) ───────────────────────────────

  /// Suma [amount] soles al inventario en memoria y notifica a los listeners.
  /// No persiste — llama a [TreeStorageService.saveTreeLocally] por separado.
  void addSun(int amount) {
    if (amount <= 0 || _currentUser == null) return;
    _currentUser!.resources.sunAmount += amount;
    notifyListeners();
  }

  /// Suma [amount] unidades de agua al inventario en memoria.
  void addWater(int amount) {
    if (amount <= 0 || _currentUser == null) return;
    _currentUser!.resources.waterAmount += amount;
    notifyListeners();
  }

  /// Suma [amount] unidades de composta al inventario en memoria.
  void addCompost(int amount) {
    if (amount <= 0 || _currentUser == null) return;
    _currentUser!.resources.compostAmount += amount;
    notifyListeners();
  }

  /// Suma [amount] unidades de fertilizante al inventario en memoria.
  void addFertilizer(int amount) {
    if (amount <= 0 || _currentUser == null) return;
    _currentUser!.resources.fertilizerAmount += amount;
    notifyListeners();
  }
}