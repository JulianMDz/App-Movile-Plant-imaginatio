import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../models/tree_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/tree_storage_service.dart';

/// Controlador de estado global del juego de plantas.
///
/// Gestiona el [TreeData] (.tree v2) como modelo primario y el [UserModel]
/// como modelo de compatibilidad interna (usado por PlantService).
///
/// Dominio de escritura (Regla de Oro):
///   🟢 Flutter escribe: recursos.sol/agua/composta, planta.estado.fase, etc.
///   🔴 Unity escribe: nivel, xp, salud, hp_actual, semillas.
///   PlantController NUNCA modifica campos 🔴.
class PlantController extends ChangeNotifier {
  final LocalStorageService _authStorage = LocalStorageService();
  final TreeStorageService _treeStorage = TreeStorageService();
  static const _uuid = Uuid();

  // ── Estado ────────────────────────────────────────────────────────────────

  TreeData? _currentTree;
  UserModel? _currentUser; // compatibilidad interna con PlantService

  // ── Getters públicos ──────────────────────────────────────────────────────

  /// Árbol de datos completo (.tree v2). Null antes de llamar a [loadCurrentTree].
  TreeData? get currentTree => _currentTree;

  /// Usuario en formato legado. Compatible con PlantService y LocalStorageService.
  UserModel? get currentUser => _currentUser;

  /// Recursos actuales (acceso rápido).
  TreeRecursos get recursos =>
      _currentTree?.recursos ?? TreeRecursos();

  /// Lista de plantas del usuario.
  List<TreePlanta> get plants => _currentTree?.plantas ?? [];

  /// Semillas del usuario (escritas por Unity).
  List<TreeSemilla> get seeds => _currentTree?.semillas ?? [];

  // ── Carga de sesión ───────────────────────────────────────────────────────

  /// Carga la sesión activa: primero intenta leer el .tree v2; si no existe,
  /// carga el UserModel legacy y construye un TreeData inicial desde él.
  Future<void> loadCurrentTree() async {
    try {
      // 1. Intentar cargar .tree v2 directamente
      _currentTree = await _treeStorage.loadTree();

      if (_currentTree != null) {
        // Sincronizar UserModel legacy desde el TreeData
        _currentUser = _userModelFromTree(_currentTree!);
        notifyListeners();
        return;
      }

      // 2. Fallback: cargar UserModel legacy y construir TreeData desde él
      final userId = await _authStorage.getCurrentSession();
      if (userId == null) return;
      _currentUser = await _authStorage.getUser(userId);
      if (_currentUser == null) return;

      _currentTree = _treeFromUserModel(_currentUser!);
      notifyListeners();
    } catch (e) {
      debugPrint('[PlantController] Error al cargar datos: $e');
    }
  }

  // ── Métodos de recursos (dominio 🟢 Flutter) ──────────────────────────────

  /// Suma [amount] soles al inventario en memoria y notifica listeners.
  /// Llama a [saveTree()] por separado para persistir.
  void addSun(int amount) {
    if (amount <= 0 || _currentTree == null) return;
    _currentTree!.recursos.sol.cantidad += amount;
    _currentUser?.resources.sunAmount += amount;
    notifyListeners();
  }

  /// Suma [amount] unidades de agua.
  void addWater(int amount) {
    if (amount <= 0 || _currentTree == null) return;
    _currentTree!.recursos.agua.cantidad += amount;
    _currentUser?.resources.waterAmount += amount;
    notifyListeners();
  }

  /// Suma [amount] unidades de composta.
  void addCompost(int amount) {
    if (amount <= 0 || _currentTree == null) return;
    _currentTree!.recursos.composta.cantidad += amount;
    _currentUser?.resources.compostAmount += amount;
    notifyListeners();
  }

  /// Suma [amount] unidades de fertilizante (solo interno — no aparece en .tree).
  void addFertilizer(int amount) {
    if (amount <= 0 || _currentUser == null) return;
    _currentUser!.resources.fertilizerAmount += amount;
    notifyListeners();
  }

  // ── Persistencia ──────────────────────────────────────────────────────────

  /// Persiste el .tree actual en SharedPreferences aplicando la lógica de
  /// merge para preservar los campos 🔴 de Unity.
  Future<void> saveTree() async {
    if (_currentTree == null) return;
    await _treeStorage.saveTreeLocally(flutterData: _currentTree!);
    // Sincronizar también el UserModel legacy
    if (_currentUser != null) {
      await _authStorage.saveUser(_currentUser!);
    }
  }

  // ── Conversiones internas ─────────────────────────────────────────────────

  /// Convierte un [UserModel] legacy al formato [TreeData] v2.
  /// Los campos 🔴 de Unity se inicializan con sus valores por defecto.
  TreeData _treeFromUserModel(UserModel user) {
    final plantas = user.plants.map((p) {
      final fase = _stageName(p.stage);
      return TreePlanta(
        id: p.plantType.name,
        instanceId: _uuid.v4().substring(0, 7), // ID de instancia corto
        subid: p.plantType.name,
        desbloqueada: !p.isDead,
        estado: TreeEstado(fase: fase),
        recursosAplicados: TreeRecursosAplicados(
          sol: p.sun.toInt(),
          agua: p.water.toInt(),
          composta: p.fertilizer.toInt(),
        ),
      );
    }).toList();

    return TreeData(
      version: 2,
      usuario: TreeUsuario(
        id: user.userId,
        nombre: user.username,
      ),
      recursos: TreeRecursos(
        sol: TreeRecurso(cantidad: user.resources.sunAmount),
        agua: TreeRecurso(cantidad: user.resources.waterAmount),
        composta: TreeRecurso(cantidad: user.resources.compostAmount),
      ),
      plantas: plantas,
    );
  }

  /// Construye un [UserModel] legacy desde [TreeData] para compatibilidad
  /// con [PlantService] y [LocalStorageService].
  UserModel _userModelFromTree(TreeData tree) {
    final plants = tree.plantas.map((p) {
      final type = _plantType(p.id);
      final stage = _plantStage(p.estado.fase);
      return PlantState(
        plantId: p.instanceId,
        plantName: p.id,
        plantType: type,
        stage: stage,
        sun: p.recursosAplicados.sol.toDouble(),
        water: p.recursosAplicados.agua.toDouble(),
        fertilizer: 0,
        isDead: p.estado.salud == 'muerto',
        lastInteraction: DateTime.now().toUtc(),
        sourcesNextState: SourcesNextState(sun: 0, water: 0, fertilizer: 0),
      );
    }).toList();

    return UserModel(
      userId: tree.usuario.id,
      username: tree.usuario.nombre,
      unlockedPlants: tree.plantas
          .where((p) => p.desbloqueada)
          .map((p) => p.id)
          .toList(),
      plants: plants,
      resources: UserResources(
        sunAmount: tree.recursos.sol.cantidad,
        waterAmount: tree.recursos.agua.cantidad,
        compostAmount: tree.recursos.composta.cantidad,
      ),
    );
  }

  // ── Helpers de mapeo ──────────────────────────────────────────────────────

  /// Mapea [PlantStage] al nombre de fase del .tree v2 (español).
  static String _stageName(PlantStage stage) {
    switch (stage) {
      case PlantStage.seed: return 'semilla';
      case PlantStage.bush: return 'arbusto';
      case PlantStage.tree: return 'planta';
      case PlantStage.ent:  return 'ent';
    }
  }

  /// Mapea la fase del .tree v2 (español) al enum [PlantStage].
  static PlantStage _plantStage(String fase) {
    switch (fase) {
      case 'semilla': return PlantStage.seed;
      case 'arbusto': return PlantStage.bush;
      case 'planta':  return PlantStage.tree;
      case 'ent':     return PlantStage.ent;
      default:        return PlantStage.seed;
    }
  }

  /// Intenta mapear el id de especie al enum [PlantType]; default: solar.
  static PlantType _plantType(String id) {
    try {
      return PlantType.values.firstWhere((e) => e.name == id);
    } catch (_) {
      return PlantType.solar;
    }
  }
}