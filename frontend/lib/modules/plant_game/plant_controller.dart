import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../models/tree_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/tree_storage_service.dart';
import '../../services/shared_tree_storage_service.dart';

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
  final SharedTreeStorageService _sharedStorage = SharedTreeStorageService();
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
        _ensureDefaultPlant();          // garantiza que siempre haya una planta activa
        applyPassiveDecay();            // aplica decay antes de mostrar estado
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
      _ensureDefaultPlant();            // garantiza planta por defecto también en fallback
      notifyListeners();
    } catch (e) {
      debugPrint('[PlantController] Error al cargar datos: $e');
    }
  }

  /// Asegura que el tree siempre tenga al menos una planta pasto desbloqueada.
  ///
  /// Si ya existe una planta con [id] == 'pasto' y [desbloqueada] == true,
  /// no hace nada. Si no hay ninguna, inserta la planta por defecto antes
  /// de que cualquier otra lógica la necesite (decay, spendXxx, etc.).
  void _ensureDefaultPlant() {
    if (_currentTree == null) return;

    final hasActivePasto = _currentTree!.plantas.any(
      (p) => p.id == 'pasto' && p.desbloqueada && p.estado.fase != 'muerto',
    );

    if (!hasActivePasto) {
      final defaultPasto = TreePlanta(
        id: 'pasto',
        instanceId: _uuid.v4(),   // UUID único e inmutable
        subid: 'pasto',
        desbloqueada: true,
        estado: TreeEstado(fase: 'semilla'),
        recursosAplicados: TreeRecursosAplicados(),
        lastInteraction: DateTime.now().toUtc(),
      );
      _currentTree!.plantas.add(defaultPasto);
      debugPrint('[PlantController] 🌱 Planta pasto por defecto añadida al tree.');
    }
  }

  // ── Decay pasivo (dominio 🟢 Flutter) ─────────────────────────────────

  /// Intervalo de decay: cada 10 minutos se pierde 1 unidad de agua y sol.
  static const int _decayIntervalMin = 10;

  /// Calcula cuántos intervalos de 10 min pasaron y descuenta recursos_aplicados.
  ///
  /// Reglas:
  ///   • Agua y Sol: −1 por cada 10 min transcurridos desde lastInteraction.
  ///   • Si agua ≤0 O sol ≤0: estado.fase = 'muerto'.
  ///   • Composta: NO decae (el usuario la acumula y aplica manualmente).
  ///   • Plantas ya muertas o no desbloqueadas: se omiten.
  ///
  /// Se llama al cargar la sesión y al importar datos de Unity.
  void applyPassiveDecay() {
    if (_currentTree == null) return;
    final now = DateTime.now().toUtc();
    bool changed = false;

    for (final plant in _currentTree!.plantas) {
      if (!plant.desbloqueada) continue;
      if (plant.estado.fase == 'muerto') continue;

      final minutesPassed =
          now.difference(plant.lastInteraction).inMinutes;
      if (minutesPassed < _decayIntervalMin) continue;

      final intervals = minutesPassed ~/ _decayIntervalMin;

      // Descontar agua y sol aplicados (no el inventario del usuario)
      plant.recursosAplicados.agua =
          (plant.recursosAplicados.agua - intervals).clamp(0, 9999);
      plant.recursosAplicados.sol =
          (plant.recursosAplicados.sol - intervals).clamp(0, 9999);

      // Condición de muerte: sin agua O sin sol
      if (plant.recursosAplicados.agua <= 0 || plant.recursosAplicados.sol <= 0) {
        plant.estado.fase = 'muerto';
        debugPrint(
          '[PlantController] 🚨 Planta ${plant.id} ha muerto por falta de recursos.'
        );
      }

      // Avanzar lastInteraction hasta el último intervalo completo procesado
      plant.lastInteraction = plant.lastInteraction.add(
        Duration(minutes: intervals * _decayIntervalMin),
      );

      changed = true;
    }

    if (changed) {
      debugPrint('[PlantController] ⏳ Decay pasivo aplicado.');
      // No llamamos saveTree() aquí para no bloquear la carga inicial;
      // el caller debe hacerlo si lo necesita persistir inmediatamente.
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

  // ── Gasto de recursos en la planta activa ──────────────────────────────────────

  /// Retorna la primera planta desbloqueada y viva, o null si no hay ninguna.
  TreePlanta? get activePlant {
    if (_currentTree == null || _currentTree!.plantas.isEmpty) return null;
    try {
      return _currentTree!.plantas.firstWhere(
        (p) => p.desbloqueada && p.estado.fase != 'muerto',
      );
    } catch (_) {
      // No hay planta viva desbloqueada
      return null;
    }
  }

  /// Gasta [amount] unidades de sol del inventario.
  /// Retorna `true` si había stock (la animación se muestra).
  /// Si hay una planta activa viva, también aplica los recursos a ella.
  bool spendSun({int amount = 1}) {
    if (_currentTree == null) return false;
    if (_currentTree!.recursos.sol.cantidad < amount) return false;
    // Descontar inventario
    _currentTree!.recursos.sol.cantidad -= amount;
    _currentUser?.resources.sunAmount -= amount;
    // Aplicar a planta activa si existe (opcional)
    final plant = activePlant;
    if (plant != null) {
      plant.recursosAplicados.sol += amount;
      plant.lastInteraction = DateTime.now().toUtc();
    }
    notifyListeners();
    return true; // siempre true si hay stock → animación siempre se dispara
  }

  /// Gasta [amount] unidades de agua del inventario.
  bool spendWater({int amount = 1}) {
    if (_currentTree == null) return false;
    if (_currentTree!.recursos.agua.cantidad < amount) return false;
    _currentTree!.recursos.agua.cantidad -= amount;
    _currentUser?.resources.waterAmount -= amount;
    final plant = activePlant;
    if (plant != null) {
      plant.recursosAplicados.agua += amount;
      plant.lastInteraction = DateTime.now().toUtc();
    }
    notifyListeners();
    return true;
  }

  /// Gasta [amount] unidades de composta del inventario.
  bool spendCompost({int amount = 1}) {
    if (_currentTree == null) return false;
    if (_currentTree!.recursos.composta.cantidad < amount) return false;
    _currentTree!.recursos.composta.cantidad -= amount;
    _currentUser?.resources.compostAmount -= amount;
    final plant = activePlant;
    if (plant != null) {
      plant.recursosAplicados.composta += amount;
      // Composta no reinicia el timer de decay
    }
    notifyListeners();
    return true;
  }

  /// Acceso rápido a los recursos aplicados de la planta activa.
  TreeRecursosAplicados get activePlantResources =>
      activePlant?.recursosAplicados ?? TreeRecursosAplicados();

  /// Persiste el .tree actual en SharedPreferences aplicando la lógica de
  /// merge para preservar los campos 🔴 de Unity.
  /// Después exporta automáticamente al archivo Documents/IMAGINATIO/Data_user.tree.
  Future<void> saveTree() async {
    if (_currentTree == null) return;
    await _treeStorage.saveTreeLocally(flutterData: _currentTree!);
    // Sincronizar también el UserModel legacy
    if (_currentUser != null) {
      await _authStorage.saveUser(_currentUser!);
    }
    // ── Auto-exportar al archivo físico compartido (silent: sin diálogos) ────
    try {
      await _sharedStorage.exportTree(_currentTree!, silent: true);
    } catch (e) {
      // No crítico: la app funciona aunque falle la exportación al archivo
      debugPrint('[PlantController] ⚠️ Auto-export fallido: $e');
    }
  }

  /// Importa el .tree desde Documents/IMAGINATIO/ (cambios escritos por Unity)
  /// y aplica solo los campos 🔴 de Unity preservando los 🟢 de Flutter.
  /// Retorna `true` si se importó exitosamente.
  Future<bool> importFromSharedStorage() async {
    try {
      // Backup defensivo antes de importar
      await _sharedStorage.createBackup('pre_unity_import');

      final unityData = await _sharedStorage.importTree();
      if (unityData == null) {
        debugPrint('[PlantController] ℹ️ No hay archivo .tree para importar.');
        return false;
      }

      // Aplicar merge (Unity → .tree local): solo actualiza campos 🔴
      await _treeStorage.applyUnitySync(unityData);

      // Recargar el estado en memoria
      _currentTree = await _treeStorage.loadTree();
      if (_currentTree != null) {
        // Aplicar decay pasivo tras el import (igual que al cargar la sesión)
        applyPassiveDecay();
        _currentUser = _userModelFromTree(_currentTree!);
      }
      notifyListeners();
      debugPrint('[PlantController] ✅ Import desde Unity aplicado.');
      return true;
    } catch (e) {
      debugPrint('[PlantController] ❌ Error importando desde Unity: $e');
      return false;
    }
  }

  /// Abre la pantalla de Ajustes para que el usuario conceda acceso a Documents.
  /// Retorna true si ya tenía permiso (no hace falta abrir Ajustes).
  /// Retorna false si abrió Ajustes (el usuario debe regresar y reintentar).
  Future<bool> requestStoragePermission() =>
      _sharedStorage.requestPermissions();

  /// Verifica si ya tiene acceso a Documents (sin mostrar diálogos).
  Future<bool> checkStoragePermission() =>
      _sharedStorage.checkPermissions();

  /// Exporta explícitamente. Solo llamar si checkStoragePermission() == true.
  Future<String> exportToSharedStorage() async {
    if (_currentTree == null) return 'Sin datos para exportar.';
    final file = await _sharedStorage.exportTree(_currentTree!, silent: false);
    if (file == null) return 'Permisos no concedidos.';
    return file.path;
  }

  /// Expone info del folder compartido para la UI de diagnóstico.
  Future<SharedFolderInfo> getSharedFolderInfo() =>
      _sharedStorage.getFolderInfo();

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