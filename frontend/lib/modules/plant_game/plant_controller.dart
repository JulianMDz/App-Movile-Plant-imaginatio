import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../models/tree_models.dart';
import '../../services/local_storage_service.dart';
import '../../services/tree_storage_service.dart';
import '../../services/shared_tree_storage_service.dart';

/// Controlador de estado global del juego de evolutionas.
///
/// Gestiona el [TreeData] (.tree v2) como modelo primario y el [UserModel]
/// como modelo de compatibilidad interna (usado por animationService).
///
/// Dominio de escritura (Regla de Oro):
///   🟢 Flutter escribe: recursos.sol/agua/composta, boola.estado.fase, etc.
///   🔴 Unity escribe: nivel, xp, salud, hp_actual, semillas.
///   PlantController NUNCA modifica campos 🔴.
class PlantController extends ChangeNotifier {
  final LocalStorageService _authStorage = LocalStorageService();
  final TreeStorageService _treeStorage = TreeStorageService();
  final SharedTreeStorageService _sharedStorage = SharedTreeStorageService();
  static const _uuid = Uuid();

  // ── Concurrency Guard for saveTree (Debounce Mechanism) ──────────────────────
  /// Prevents concurrent save operations; if a save is already in progress,
  /// subsequent calls return immediately without queuing.
  /// This ensures no data loss or corruption from overlapping writes.
  bool _isSaving = false;
  
  /// Optional queue counter for future batching (if rapid-fire saves required).
  int _savingQueueCount = 0;

  // ── Minigame Overlay Debounce Guards ───────────────────────────────────────
  /// Prevents double-tap or rapid re-activation of minigame overlays.
  /// Set to true when overlay is being launched; reset when overlay closes.
  bool _sunOverlayActive = false;
  bool _waterOverlayActive = false;
  bool _compostOverlayActive = false;

  // ── Cooldowns de Minijuegos (persisten entre sesiones via SharedPreferences) ─
  static const Duration sunGameCooldown = Duration(minutes: 10);
  static const Duration waterGameCooldown = Duration(minutes: 10);
  static const Duration compostGameCooldown = Duration(minutes: 3);

  // Keys para SharedPreferences
  static const String _cooldownSunKey = 'cooldown_sun';
  static const String _cooldownWaterKey = 'cooldown_water';
  static const String _cooldownCompostKey = 'cooldown_compost';

  // Timestamps de último juego (cargados desde SharedPreferences)
  DateTime? _lastSunGameTime;
  DateTime? _lastWaterGameTime;
  DateTime? _lastCompostGameTime;

  // ── Requisitos de evolución por tipo y etapa ─────────────────────────────────
  // Formato: {tipo: {fase: {sun: X, water: Y}}}
  static const Map<String, Map<String, Map<String, int>>> _evolutionRequirements = {
    'solar': {
      'semilla': {'sun': 6, 'water': 2},
      'arbusto': {'sun': 8, 'water': 4},
      'planta': {'sun': 10, 'water': 6},
    },
    'xerofito': {
      'semilla': {'sun': 4, 'water': 2},
      'arbusto': {'sun': 6, 'water': 4},
      'planta': {'sun': 8, 'water': 6},
    },
    'templado': {
      'semilla': {'sun': 4, 'water': 4},
      'arbusto': {'sun': 6, 'water': 6},
      'planta': {'sun': 8, 'water': 8},
    },
    'montana': {
      'semilla': {'sun': 2, 'water': 4},
      'arbusto': {'sun': 4, 'water': 6},
      'planta': {'sun': 6, 'water': 8},
    },
    'hidro': {
      'semilla': {'sun': 2, 'water': 6},
      'arbusto': {'sun': 4, 'water': 8},
      'planta': {'sun': 6, 'water': 10},
    },
    'pasto': {
      'semilla': {'sun': 3, 'water': 3},
      'arbusto': {'sun': 5, 'water': 5},
      'planta': {'sun': 7, 'water': 7},
    },
  };

  // Fertilizante requerido por etapa (igual para todos los tipos)
  static const Map<String, int> _fertilizerRequirements = {
    'semilla': 4,
    'arbusto': 6,
    'planta': 8,
  };

  // Recursos mínimos para cada fase (al evolucionar se resetean a estos valores)
  static const Map<String, Map<String, int>> _minResourcesByPhase = {
    'semilla': {'sol': 1, 'agua': 1, 'fertilizante': 0},
    'arbusto': {'sol': 1, 'agua': 1, 'fertilizante': 0},
    'planta': {'sol': 1, 'agua': 1, 'fertilizante': 0},
    'ent': {'sol': 1, 'agua': 1, 'fertilizante': 0},
  };

  Map<String, int> _getMinResourcesForPhase(String fase) {
    return _minResourcesByPhase[fase] ?? {'sol': 1, 'agua': 1, 'fertilizante': 0};
  }

  /// Returns the maximum resources a plant can hold in its current phase
  /// (equal to the evolution threshold, or null if dead/unknown).
  /// ENT phase uses 'planta' values since there is no further evolution.
  Map<String, int>? _getMaxResourcesForPlant(TreePlanta plant) {
    final fase = plant.estado.fase;
    if (fase == 'muerto') return null;
    final plantType = _getPlantType(plant.id);
    final faseKey = fase == 'ent' ? 'planta' : fase;
    final faseReqs = _evolutionRequirements[plantType]?[faseKey];
    if (faseReqs == null) return null;
    return {
      'sol': faseReqs['sun'] ?? 10,
      'agua': faseReqs['water'] ?? 10,
      'fertilizante': _fertilizerRequirements[faseKey] ?? 8,
    };
  }

  // ── Clasificación de plantas por nombre de carpeta ───────────────────────────
  // Mapea nombres de carpetas de Unity al tipo de planta
  static String _getPlantType(String folderName) {
    final lowerName = folderName.toLowerCase();
    
    // XEROFITO (primero los más específicos)
    if (lowerName.contains('alcaparro enano')) return 'xerofito';
    if (lowerName.contains('dividivi')) return 'xerofito';
    
    // SOLAR
    if (lowerName.contains('alcaparro grande')) return 'solar';
    if (lowerName.contains('alcaparro')) return 'solar';
    if (lowerName.contains('cajeto')) return 'solar';
    if (lowerName.contains('espino')) return 'solar';
    if (lowerName.contains('drago')) return 'solar';
    
    // MONTAÑA
    if (lowerName.contains('pino romerón')) return 'montana';
    if (lowerName.contains('roble')) return 'montana';
    if (lowerName.contains('nogal')) return 'montana';
    if (lowerName.contains('duraznillo')) return 'montana';
    
    // TEMPLADO
    if (lowerName.contains('manzano')) return 'templado';
    if (lowerName.contains('mangle')) return 'templado';
    if (lowerName.contains('sietecueros')) return 'templado';
    if (lowerName.contains('cedro')) return 'templado';
    
    // HIDRO
    if (lowerName.contains('cucharo negro')) return 'hidro';
    if (lowerName.contains('aliso')) return 'hidro';
    if (lowerName.contains('cedrillo')) return 'hidro';
    
    // PASTO (default/base)
    return 'pasto';
  }

  /// Retorna el tipo de planta basado en el nombre/id de la carpeta
  String getPlantType(String folderName) => _getPlantType(folderName);

  bool _showEvolutionAnimation = false;
  String? _plantUpdateEvent;
  String? get plantUpdateEvent => _plantUpdateEvent;

  // ── Estado ────────────────────────────────────────────────────────────────

  TreeData? _currentTree;
  UserModel? _currentUser; // compatibilidad interna con PlantService
  int _activePlantIndex = 0; // Índice de la planta actualmente seleccionada

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

      // Bug 3: Debug para ver el estado de las plantas al cargar
      if (_currentTree != null) {
        final plantasInfo = _currentTree!.plantas.map((p) => '${p.id}:fase=${p.estado.fase}').join(', ');
        debugPrint('[PlantController] 📋 Plantas cargadas desde .tree: $plantasInfo');
      } else {
        debugPrint('[PlantController] 📋 No se encontró .tree, se creará nuevo');
      }

      if (_currentTree != null) {
        _ensureDefaultPlant();
        await applyPassiveDecay();
        await saveTreeDebounced(); // Use debounced version to prevent concurrency
        _currentUser = _userModelFromTree(_currentTree!);
        await _loadCooldowns();
        notifyListeners();
        return;
      }

      // 2. Fallback: cargar UserModel legacy y construir TreeData desde él
      final userId = await _authStorage.getCurrentSession();
      if (userId == null) return;
      _currentUser = await _authStorage.getUser(userId);
      if (_currentUser == null) return;

      _currentTree = _treeFromUserModel(_currentUser!);
      _ensureDefaultPlant();
      await saveTreeDebounced();            // Use debounced version; persiste el tree con la planta pasto inicial
      await _loadCooldowns();               // cargar cooldowns desde SharedPreferences
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

    // Run when there are no plants at all OR all existing plants are dead
    final aliveCount = _currentTree!.plantas
        .where((p) => p.desbloqueada && p.estado.fase != 'muerto')
        .length;
    if (aliveCount > 0) return;

    final instanceId = _uuid.v4();
    final plant = TreePlanta(
      id: 'pasto',
      instanceId: instanceId,
      subid: 'pasto',
      desbloqueada: true,
      estado: TreeEstado(fase: 'semilla'),
      // Minimum resources to survive — user must interact immediately
      recursosAplicados: TreeRecursosAplicados(sol: 1, agua: 1, fertilizante: 0),
    );
    _currentTree!.plantas.add(plant);
    _activePlantIndex = 0;
    _authStorage.savePlantLastInteraction(instanceId, DateTime.now().toUtc());
    debugPrint('[PlantController] 🌱 Nueva planta pasto creada (sin plantas vivas disponibles)');
  }

  // ── Decay pasivo (dominio 🟢 Flutter) ─────────────────────────────────

  /// Intervalo de decay: cada 10 minutos se pierde 1 unidad de agua y sol.
  static const int _decayIntervalMin = 10;

  /// Calcula cuántos intervalos de 10 min pasaron y descuenta recursos_aplicados.
  ///
  /// Reglas:
  ///   • Solo aplica decay a la planta activa (seleccionada por el usuario).
  ///   • Agua y Sol: −1 por cada 10 min transcurridos desde lastInteraction.
  ///   • Si agua ≤0 O sol ≤0: estado.fase = 'muerto'.
  ///   • Composta: NO decae (el usuario la acumula y aplica manualmente).
  ///   • Plantas no activas: no se les aplica decay.
  ///
  /// Se llama al cargar la sesión y al importar datos de Unity.
  /// [fakeNow]: parámetro opcional para testing/debug - simula que el tiempo actual es diferente.
  Future<void> applyPassiveDecay({DateTime? fakeNow}) async {
    if (_currentTree == null) return;

    final plant = activePlant;
    if (plant == null) return;

    // Si la planta está en fase ENT, no aplicar decay (ya está madura)
    if (plant.estado.fase == 'ent') return;

    final now = fakeNow ?? DateTime.now().toUtc();
    debugPrint('[Decay] 🔧 Usando tiempo: ${now.toIso8601String()} (fakeNow: ${fakeNow != null})');
    final lastInteraction = await _authStorage.getPlantLastInteraction(plant.instanceId);
    debugPrint('[Decay] 📅 lastInteraction actual: ${lastInteraction.toIso8601String()}');

    final minutesPassed = now.difference(lastInteraction).inMinutes;
    debugPrint('[Decay] ⏱️ Minutos desde última interacción: $minutesPassed (intervalo=10min)');

    if (minutesPassed < _decayIntervalMin) {
      debugPrint('[Decay] ⏭️ No se aplica decay: minutos ($minutesPassed) < intervalo (${_decayIntervalMin}min)');
      return;
    }

    final intervals = minutesPassed ~/ _decayIntervalMin;
    debugPrint('[Decay] 🔢 Intervalos de decay a aplicar: $intervals');

    final solAntes = plant.recursosAplicados.sol;
    final aguaAntes = plant.recursosAplicados.agua;
    debugPrint('[Decay] 🔴 Recursos ANTES del decay: sol=$solAntes, agua=$aguaAntes');

    plant.recursosAplicados.agua =
        (plant.recursosAplicados.agua - intervals).clamp(0, 9999);
    plant.recursosAplicados.sol =
        (plant.recursosAplicados.sol - intervals).clamp(0, 9999);

    debugPrint('[Decay] 🟢 Recursos DESPUÉS del decay: sol=${plant.recursosAplicados.sol}, agua=${plant.recursosAplicados.agua}');

    if (plant.recursosAplicados.agua <= 0 || plant.recursosAplicados.sol <= 0) {
      plant.estado.fase = 'muerto';
      debugPrint('[PlantController] 🚨 Planta ${plant.id} muerta por decay.');
      _ensureDefaultPlant(); // Respawn pasto if no alive plants remain
    }

    // Actualizar lastInteraction al tiempo actual (fakeNow si está en modo debug)
    // Esto asegura que el próximo decay calcule correctamente los minutos transcurridos
    final newInteraction = fakeNow ?? DateTime.now().toUtc();
    debugPrint('[Decay] 📅 Actualizando lastInteraction a: ${newInteraction.toIso8601String()}');
    await _authStorage.savePlantLastInteraction(plant.instanceId, newInteraction);
    await saveTreeDebounced(); // Use debounced version; persistir cambios del decay
    notifyListeners(); // Actualizar UI (barras de recursos + animaciones de urgencia)

    debugPrint('[PlantController] ⏳ Decay aplicado solo a planta activa: ${plant.id}');
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
    
    // Conversión automática: 4 compost = 1 fertilizante
    final totalCompost = _currentTree!.recursos.composta.cantidad;
    if (totalCompost >= 4) {
      final fertilizerGained = totalCompost ~/ 4;
      final remainingCompost = totalCompost % 4;
      _currentTree!.recursos.composta.cantidad = remainingCompost;
      _currentTree!.recursos.fertilizante.cantidad += fertilizerGained;
      _currentUser?.resources.fertilizerAmount += fertilizerGained;
    }
    
    notifyListeners();
  }

  /// Suma [amount] unidades de fertilizante al inventario.
  void addFertilizer(int amount) {
    if (amount <= 0 || _currentTree == null) return;
    _currentTree!.recursos.fertilizante.cantidad += amount;
    _currentUser?.resources.fertilizerAmount += amount;
    notifyListeners();
  }

  /// Convierte composta del inventario a fertilizante en la planta activa.
  /// 4 compost = 1 fertilizante. Llámalo después de addCompost().
  void convertCompostToFertilizer() {
    if (_currentTree == null) return;
    
    final totalCompost = _currentTree!.recursos.composta.cantidad;
    if (totalCompost < 4) return;

    final fertilizerGained = totalCompost ~/ 4;
    final remainingCompost = totalCompost % 4;

    // Descontar la composta convertida
    _currentTree!.recursos.composta.cantidad = remainingCompost;

    // Agregar fertilizante a la planta activa
    final plant = activePlant;
    if (plant != null && fertilizerGained > 0) {
      plant.recursosAplicados.fertilizante += fertilizerGained;
      notifyListeners();
    }
  }

  // ── Gasto de recursos en la planta activa ──────────────────────────────────────

  /// Retorna la planta activa según el índice seleccionado.
  ///
  /// Defensive guards:
  /// - Returns null if _currentTree is null
  /// - Validates _activePlantIndex is within bounds (FIX 7: post-sync validation)
  /// - Handles empty or all-dead plant lists gracefully
  /// - Auto-initializes recursosAplicados if null
  TreePlanta? get activePlant {
    // Guard 1: Ensure tree is loaded
    if (_currentTree == null) {
      debugPrint('[PlantController] ⚠️ activePlant: currentTree is null');
      return null;
    }

    // Guard 2: Filter to valid, alive plants
    final plants = _currentTree!.plantas.where((p) => p.desbloqueada && p.estado.fase != 'muerto').toList();
    if (plants.isEmpty) {
      debugPrint('[PlantController] ⚠️ activePlant: no alive, unlocked plants available');
      return null;
    }

    // Guard 3: Validate index is within bounds (FIX 7 helps prevent OOB after sync)
    if (_activePlantIndex < 0 || _activePlantIndex >= plants.length) {
      debugPrint('[PlantController] ⚠️ FIX 7: activePlant: index $_activePlantIndex out of bounds (max ${plants.length - 1}); resetting to 0');
      _activePlantIndex = 0;
    }

    final plant = plants[_activePlantIndex];
    
    // Guard 4: Validate plant object is properly initialized
    if (plant.recursosAplicados == null) {
      debugPrint('[PlantController] ⚠️ activePlant: ${plant.id} recursosAplicados is null; initializing');
      plant.recursosAplicados = TreeRecursosAplicados();
    }

    return plant;
  }

  /// Retorna la planta por índice directo (para inventario).
  TreePlanta? getPlantByIndex(int index) {
    if (_currentTree == null || index < 0 || index >= _currentTree!.plantas.length) {
      return null;
    }
    return _currentTree!.plantas[index];
  }

  /// Establece la planta activa por índice.
  Future<void> setActivePlant(int index) async {
    final plants = _currentTree?.plantas.where((p) => p.desbloqueada && p.estado.fase != 'muerto').toList() ?? [];
    if (plants.isEmpty || index < 0 || index >= plants.length) return;

    // Buscar el índice real en la lista completa
    final targetPlant = plants[index];
    final realIndex = _currentTree!.plantas.indexOf(targetPlant);
    _activePlantIndex = realIndex;

    // Si la planta está en fase ENT, poner recursos al máximo de la fase planta
    if (targetPlant.estado.fase == 'ent') {
      final plantType = _getPlantType(targetPlant.id);
      final requirements = _evolutionRequirements[plantType];
      final plantaMax = requirements?['planta'] ?? {'sun': 10, 'water': 8};

      targetPlant.recursosAplicados.sol = plantaMax['sun'] ?? 10;
      targetPlant.recursosAplicados.agua = plantaMax['water'] ?? 8;
      targetPlant.recursosAplicados.fertilizante = 8;
    }

    debugPrint('[PlantController] Planta activa establecida: índice $realIndex');
    notifyListeners();
  }

  /// Gasta [amount] unidades de sol del inventario.
  /// Retorna `true` si había stock (la animación se muestra).
  /// Si hay una planta activa viva, también aplica los recursos a ella.
  /// 
  /// Defensive checks:
  /// - Validates _currentTree is not null
  /// - Validates activePlant is not null before applying resources
  /// - Validates plant.recursosAplicados is properly initialized
  Future<bool> spendSun({int amount = 1}) async {
    // Guard 1: Ensure tree is loaded
    if (_currentTree == null) {
      debugPrint('[PlantController] ⚠️ Cannot spend sun: currentTree is null');
      return false;
    }

    // Guard 2: Check available stock
    if (_currentTree!.recursos.sol.cantidad < amount) {
      debugPrint('[PlantController] ⚠️ Cannot spend sun: insufficient stock (have ${_currentTree!.recursos.sol.cantidad}, need $amount)');
      return false;
    }

    // Guard 3: Check plant capacity cap
    final _plantForCapCheck = activePlant;
    if (_plantForCapCheck != null) {
      final maxRes = _getMaxResourcesForPlant(_plantForCapCheck);
      if (maxRes != null && _plantForCapCheck.recursosAplicados.sol >= (maxRes['sol'] ?? 9999)) {
        debugPrint('[PlantController] ⚠️ spendSun blocked: plant already at max sol (${_plantForCapCheck.recursosAplicados.sol}/${maxRes['sol']})');
        return false;
      }
    }

    // Deduct from inventory
    _currentTree!.recursos.sol.cantidad -= amount;
    _currentUser?.resources.sunAmount -= amount;

    // Guard 3: Apply to active plant if exists
    final plant = activePlant;
    if (plant != null) {
      // Guard 4: Validate plant resources are initialized
      if (plant.recursosAplicados == null) {
        debugPrint('[PlantController] ⚠️ Plant ${plant.id} recursosAplicados is null; initializing');
        plant.recursosAplicados = TreeRecursosAplicados();
      }

      plant.recursosAplicados.sol += amount;
      _checkEvolution(plant);
      
      // Guard 5: Update lastInteraction safely
      try {
        await _authStorage.savePlantLastInteraction(plant.instanceId, DateTime.now().toUtc());
      } catch (e) {
        debugPrint('[PlantController] ⚠️ Error updating lastInteraction: $e');
      }

      saveTreeDebounced(); // Fire-and-forget with debounce protection
    }

    notifyListeners();
    return true; // siempre true si hay stock → animación siempre se dispara
  }

  /// Gasta [amount] unidades de agua del inventario.
  /// 
  /// Defensive checks:
  /// - Validates _currentTree is not null
  /// - Validates activePlant is not null before applying resources
  /// - Validates plant.recursosAplicados is properly initialized
  Future<bool> spendWater({int amount = 1}) async {
    // Guard 1: Ensure tree is loaded
    if (_currentTree == null) {
      debugPrint('[PlantController] ⚠️ Cannot spend water: currentTree is null');
      return false;
    }

    // Guard 2: Check available stock
    if (_currentTree!.recursos.agua.cantidad < amount) {
      debugPrint('[PlantController] ⚠️ Cannot spend water: insufficient stock (have ${_currentTree!.recursos.agua.cantidad}, need $amount)');
      return false;
    }

    // Guard 3: Check plant capacity cap
    final _plantForCapCheck = activePlant;
    if (_plantForCapCheck != null) {
      final maxRes = _getMaxResourcesForPlant(_plantForCapCheck);
      if (maxRes != null && _plantForCapCheck.recursosAplicados.agua >= (maxRes['agua'] ?? 9999)) {
        debugPrint('[PlantController] ⚠️ spendWater blocked: plant already at max agua (${_plantForCapCheck.recursosAplicados.agua}/${maxRes['agua']})');
        return false;
      }
    }

    _currentTree!.recursos.agua.cantidad -= amount;
    _currentUser?.resources.waterAmount -= amount;

    final plant = activePlant;
    if (plant != null) {
      // Guard 3: Validate plant resources are initialized
      if (plant.recursosAplicados == null) {
        debugPrint('[PlantController] ⚠️ Plant ${plant.id} recursosAplicados is null; initializing');
        plant.recursosAplicados = TreeRecursosAplicados();
      }

      plant.recursosAplicados.agua += amount;
      _checkEvolution(plant);

      // Guard 4: Update lastInteraction safely
      try {
        await _authStorage.savePlantLastInteraction(plant.instanceId, DateTime.now().toUtc());
      } catch (e) {
        debugPrint('[PlantController] ⚠️ Error updating lastInteraction: $e');
      }

      saveTreeDebounced(); // Fire-and-forget with debounce protection
    }

    notifyListeners();
    return true;
  }

  /// Gasta [amount] unidades de fertilizante del inventario.
  /// Añade [amount] fertilizante a la planta activa.
  ///
  /// Defensive checks:
  /// - Validates _currentTree is not null
  /// - Validates activePlant is not null before applying resources
  /// - Validates plant.recursosAplicados is properly initialized
  Future<bool> spendCompost({int amount = 1}) async {
    // Guard 1: Ensure tree is loaded
    if (_currentTree == null) {
      debugPrint('[PlantController] ⚠️ Cannot spend compost: currentTree is null');
      return false;
    }

    // Guard 2: Check available stock
    if (_currentTree!.recursos.fertilizante.cantidad < amount) {
      debugPrint('[PlantController] ⚠️ Cannot spend compost: insufficient stock (have ${_currentTree!.recursos.fertilizante.cantidad}, need $amount)');
      return false;
    }

    // Guard 3: Check plant capacity cap
    final _plantForCapCheck = activePlant;
    if (_plantForCapCheck != null) {
      final maxRes = _getMaxResourcesForPlant(_plantForCapCheck);
      if (maxRes != null && _plantForCapCheck.recursosAplicados.fertilizante >= (maxRes['fertilizante'] ?? 9999)) {
        debugPrint('[PlantController] ⚠️ spendCompost blocked: plant already at max fertilizante (${_plantForCapCheck.recursosAplicados.fertilizante}/${maxRes['fertilizante']})');
        return false;
      }
    }

    _currentTree!.recursos.fertilizante.cantidad -= amount;
    _currentUser?.resources.fertilizerAmount -= amount;

    final plant = activePlant;
    if (plant != null) {
      // Guard 3: Validate plant resources are initialized
      if (plant.recursosAplicados == null) {
        debugPrint('[PlantController] ⚠️ Plant ${plant.id} recursosAplicados is null; initializing');
        plant.recursosAplicados = TreeRecursosAplicados();
      }

      plant.recursosAplicados.fertilizante += amount;
      _checkEvolution(plant);

      // Guard 4: Update lastInteraction safely
      try {
        await _authStorage.savePlantLastInteraction(plant.instanceId, DateTime.now().toUtc());
      } catch (e) {
        debugPrint('[PlantController] ⚠️ Error updating lastInteraction: $e');
      }

      saveTreeDebounced(); // Fire-and-forget with debounce protection
    }

    notifyListeners();
    return true;
  }

  // ── Sistema de Evolución ─────────────────────────────────────────────────────

  /// Retorna true si hay animación de evolución pendiente
  bool get showEvolutionAnimation => _showEvolutionAnimation;

  /// Limpia el flag de evolución tras consumirlo en la UI
  void clearAnimationFlags() {
    _showEvolutionAnimation = false;
  }

  /// Obtiene los requisitos para la siguiente etapa de la planta activa
  Map<String, int>? getNextStageRequirements() {
    final plant = activePlant;
    if (plant == null) return null;

    final currentFase = plant.estado.fase;
    if (currentFase == 'ent') return null;

    final plantType = plant.id;
    final requirements = _evolutionRequirements[plantType];
    if (requirements == null) return null;

    String faseKey;
    switch (currentFase) {
      case 'semilla':
        faseKey = 'semilla';
        break;
      case 'arbusto':
        faseKey = 'arbusto';
        break;
      case 'planta':
        faseKey = 'planta';
        break;
      default:
        return null;
    }

    return {
      'sol': requirements[faseKey]?['sun'] ?? 0,
      'agua': requirements[faseKey]?['water'] ?? 0,
      'fertilizante': _fertilizerRequirements[faseKey] ?? 0,
    };
  }

  /// Retorna los recursos máximos que la planta puede consumir en su fase actual.
  /// Usado para calcular el % de llenado en las barras del panel de recursos.
  /// Por ejemplo: solar en fase "semilla" → {sol: 6, agua: 2, fertilizante: 4}
  Map<String, int>? getCurrentPhaseRequirements() {
    final plant = activePlant;
    if (plant == null) return null;
    
    final currentFase = plant.estado.fase;
    
    // Si la planta está en fase ENT, usar los valores de fase "planta" (la máxima)
    if (currentFase == 'ent') {
      final plantType = _getPlantType(plant.id);
      final requirements = _evolutionRequirements[plantType];
      if (requirements == null) return null;
      final faseReqs = requirements['planta'];
      if (faseReqs == null) return null;
      return {
        'sol': faseReqs['sun'] ?? 10,
        'agua': faseReqs['water'] ?? 10,
        'fertilizante': _fertilizerRequirements['planta'] ?? 10,
      };
    }
    
    // Usar _getPlantType para obtener la key correcta (solar, hidro, etc.)
    final plantType = _getPlantType(plant.id);
    final requirements = _evolutionRequirements[plantType];
    if (requirements == null) return null;
    
    final faseReqs = requirements[currentFase];
    if (faseReqs == null) return null;
    
    return {
      'sol': faseReqs['sun'] ?? 10,
      'agua': faseReqs['water'] ?? 10,
      'fertilizante': _fertilizerRequirements[currentFase] ?? 10,
    };
  }

  /// Verifica si la planta activa puede evolucionar a la siguiente etapa
  bool canEvolve() {
    final plant = activePlant;
    if (plant == null) return false;

    final currentFase = plant.estado.fase;
    if (currentFase == 'ent') return false;

    final requirements = getNextStageRequirements();
    if (requirements == null) return false;

    final sol = plant.recursosAplicados?.sol ?? 0;
    final agua = plant.recursosAplicados?.agua ?? 0;
    final fertilizante = plant.recursosAplicados?.fertilizante ?? 0;

    return sol >= (requirements['sol'] ?? 0) &&
           agua >= (requirements['agua'] ?? 0) &&
           fertilizante >= (requirements['fertilizante'] ?? 0);
  }

  /// Evoluciona la planta activa a la siguiente etapa
  bool evolve() {
    
    final plant = activePlant;
  if (plant == null || !canEvolve()) return false;

  final currentFase = plant.estado.fase;
  String nextFase;

    switch (currentFase) {
      case 'semilla':
        nextFase = 'arbusto';
        break;
      case 'arbusto':
        nextFase = 'planta';
        break;
      case 'planta':
        nextFase = 'ent';
        break;
      default:
        return false;
    }

    plant.estado.fase = nextFase;
    _showEvolutionAnimation = true;

    debugPrint('[PlantController] 🌱 Planta evolucionó a: $nextFase');
    _plantUpdateEvent = plant.id; 
    notifyListeners();
    return true;
  }

  /// Verifica la salud de la planta y actualiza los flags de animación
  void checkPlantHealth() {
    final plant = activePlant;
    if (plant == null) return;

    final sol = plant.recursosAplicados?.sol ?? 0;
    final agua = plant.recursosAplicados?.agua ?? 0;

    if (sol <= 0 || agua <= 0) {
      plant.estado.fase = 'muerto';
      debugPrint('[PlantController] 💀 Planta ${plant.id} murió.');
      _ensureDefaultPlant(); // Respawn pasto if no alive plants remain
    }

    notifyListeners();
  }

  /// Verifica si la planta puede evolucionar y la evoluciona si es posible
  void _checkEvolution(TreePlanta plant) {
    if (plant.estado.fase == 'ent') return;

    final plantType = _getPlantType(plant.id);
    final requirements = _evolutionRequirements[plantType];
    if (requirements == null) return;

    String faseKey;
    switch (plant.estado.fase) {
      case 'semilla':
        faseKey = 'semilla';
        break;
      case 'arbusto':
        faseKey = 'arbusto';
        break;
      case 'planta':
        faseKey = 'planta';
        break;
      default:
        return;
    }

    final requiredSol = requirements[faseKey]?['sun'] ?? 0;
    final requiredAgua = requirements[faseKey]?['water'] ?? 0;
    final requiredFertilizante = _fertilizerRequirements[faseKey] ?? 0;

    final sol = plant.recursosAplicados?.sol ?? 0;
    final agua = plant.recursosAplicados?.agua ?? 0;
    final fertilizante = plant.recursosAplicados?.fertilizante ?? 0;

    if (sol >= requiredSol && agua >= requiredAgua && fertilizante >= requiredFertilizante) {
      String nextFase;
      switch (plant.estado.fase) {
        case 'semilla':
          nextFase = 'arbusto';
          break;
        case 'arbusto':
          nextFase = 'planta';
          break;
        case 'planta':
          nextFase = 'ent';
          break;
        default:
          return;
      }

      plant.estado.fase = nextFase;
      
      // Resetear recursos al mínimo de la nueva fase
      final minResources = _getMinResourcesForPhase(nextFase);
      plant.recursosAplicados.sol = minResources['sol'] ?? 1;
      plant.recursosAplicados.agua = minResources['agua'] ?? 1;
      plant.recursosAplicados.fertilizante = minResources['fertilizante'] ?? 0;
      
      _showEvolutionAnimation = true;
      debugPrint('[PlantController] 🌱 Planta evolucionó automáticamente a: $nextFase (recursos reseteados: sol=${plant.recursosAplicados.sol}, agua=${plant.recursosAplicados.agua}, fertilizante=${plant.recursosAplicados.fertilizante})');
    }
  }

  /// Acceso rápido a los recursos aplicados de la planta activa.
  TreeRecursosAplicados get activePlantResources =>
      activePlant?.recursosAplicados ?? TreeRecursosAplicados();

  // ── Métodos de Debug ───────────────────────────────────────────────────────

  /// Retorna información de debug de las plantas (para panel de debug).
  String getDebugPlantsInfo() {
    final plants = this.plants;
    if (plants.isEmpty) return 'Sin plantas';

    final buffer = StringBuffer();
    for (int i = 0; i < plants.length; i++) {
      final p = plants[i];
      final sol = p.recursosAplicados?.sol ?? 0;
      final agua = p.recursosAplicados?.agua ?? 0;
      final fase = p.estado?.fase ?? 'desconocido';
      buffer.writeln('P$i: S:$sol A:$agua F:$fase');
    }
    return buffer.toString();
  }

  /// Flag para evitar múltiples ejecuciones rápidas del debugAdvanceTime
  bool _isDebugAdvancing = false;

  /// Minutos acumulados de debug (para que múltiples clicks de "T" acumulen tiempo)
  static int _debugTimeMinutesAccumulated = 0;

  /// Resetea el tiempo acumulado de debug (para正常使用)
  void resetDebugTime() {
    _debugTimeMinutesAccumulated = 0;
    debugPrint('[Debug] 🔄 Tiempo acumulado de debug reseteado');
  }

  /// Avanza el tiempo de todas las plantas por [minutes] minutos (para debug).
  /// También avanza los cooldowns de los minijuegos y aplica el decay.
  Future<void> debugAdvanceTime(int minutes) async {
    if (_isDebugAdvancing) return;
    _isDebugAdvancing = true;
    
    try {
      // Acumular minutos de debug para que múltiples clicks sumen
      _debugTimeMinutesAccumulated += minutes;
      debugPrint('[Debug] ⏱️ Minutos acumulados de debug: $_debugTimeMinutesAccumulated');
      
      // 1. Retroceder cooldowns de minijuegos (restar tiempo para poder jugar antes)
      if (_lastSunGameTime != null) {
        _lastSunGameTime = _lastSunGameTime!.subtract(Duration(minutes: minutes));
      }
      if (_lastWaterGameTime != null) {
        _lastWaterGameTime = _lastWaterGameTime!.subtract(Duration(minutes: minutes));
      }
      if (_lastCompostGameTime != null) {
        _lastCompostGameTime = _lastCompostGameTime!.subtract(Duration(minutes: minutes));
      }
      await _saveCooldowns();
      
      // 2. Aplicar decay usando fakeNow para simular tiempo avanzado
      final plantAntes = activePlant;
      if (plantAntes != null) {
        debugPrint('[Debug] 📊 Recursos ANTES de applyPassiveDecay: sol=${plantAntes.recursosAplicados.sol}, agua=${plantAntes.recursosAplicados.agua}');
      }
      // Simular que pasaron los minutos acumulados de debug
      final fakeNow = DateTime.now().toUtc().add(Duration(minutes: _debugTimeMinutesAccumulated));
      debugPrint('[Debug] ⏱️ fakeNow = now + $_debugTimeMinutesAccumulated minutos');
      await applyPassiveDecay(fakeNow: fakeNow);
      final plantDepois = activePlant;
      if (plantDepois != null) {
        debugPrint('[Debug] 📊 Recursos DESPUÉS de applyPassiveDecay: sol=${plantDepois.recursosAplicados.sol}, agua=${plantDepois.recursosAplicados.agua}');
      }
      
      debugPrint('[Debug] ⏱️ Tiempo avanzado $minutes minutos + decay aplicado + cooldowns reseteados');
    } finally {
      _isDebugAdvancing = false;
    }
  }

  /// Saves tree state with concurrency protection (debounce).
  /// If a save is already in progress, returns immediately to prevent
  /// concurrent writes and data corruption.
  ///
  /// This is the preferred method for all save operations.
  /// Use directly from minigame overlays, resource spending, and decay.
  ///
  /// Flow:
  /// 1. Check if save is in progress; return early if so
  /// 2. Set _isSaving flag
  /// 3. Perform full save (saveTreeLocally + exportTree)
  /// 4. Clear _isSaving flag
  /// 5. Log result and notify listeners
  Future<void> saveTreeDebounced() async {
    // Guard 1: Prevent concurrent saves
    if (_isSaving) {
      debugPrint('[PlantController] ℹ️ Save already in progress; skipping duplicate');
      return;
    }

    _isSaving = true;
    try {
      // Guard 2: Ensure tree exists
      if (_currentTree == null) {
        debugPrint('[PlantController] ⚠️ Cannot save: currentTree is null');
        return;
      }

      // Perform full save with field authority enforcement
      await _treeStorage.saveTreeLocally(flutterData: _currentTree!);

      // Sync legacy UserModel
      if (_currentUser != null) {
        await _authStorage.saveUser(_currentUser!);
      }

      // Auto-export to shared storage (non-critical; errors logged silently)
      try {
        await _sharedStorage.exportTree(_currentTree!, silent: true);
      } catch (e) {
        debugPrint('[PlantController] ⚠️ Auto-export to shared storage failed: $e');
      }

      debugPrint('[PlantController] ✅ Tree saved successfully (debounced)');
    } catch (e) {
      debugPrint('[PlantController] ❌ Error saving tree: $e');
      // Rethrow to allow calling code to handle critical save failures
      rethrow;
    } finally {
      _isSaving = false;
    }
  }

  /// Persiste el .tree actual en SharedPreferences aplicando la lógica de
  /// merge para preservar los campos 🔴 de Unity.
  /// Después exporta automáticamente al archivo Documents/IMAGINATIO/Data_user.tree.
  ///
  /// DEPRECATED: Use saveTreeDebounced() instead to prevent concurrency issues.
  /// This method is kept for backward compatibility during migration.
  Future<void> saveTree() async {
    // Delegate to debounced version to ensure concurrency protection
    await saveTreeDebounced();
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

      // FIX 2a: ANTES de aplicar sync, guardar instanceId de planta activa actual
      final previousActivePlantId = activePlant?.instanceId;
      debugPrint('[PlantController] 🔖 FIX 2a: Saved previous active plant ID: $previousActivePlantId');

      // Aplicar merge (Unity → .tree local): solo actualiza campos 🔴
      await _treeStorage.applyUnitySync(unityData);

      // Recargar el estado en memoria
      _currentTree = await _treeStorage.loadTree();
      if (_currentTree != null) {
        // Aplicar decay pasivo tras el import (igual que al cargar la sesión)
        await applyPassiveDecay();
        _currentUser = _userModelFromTree(_currentTree!);

        // FIX 2b: DESPUÉS de sync, restaurar planta activa por instanceId
        if (previousActivePlantId != null && previousActivePlantId.isNotEmpty) {
          TreePlanta? previousPlant;
          try {
            previousPlant = _currentTree!.plantas
                .firstWhere((p) => p.instanceId == previousActivePlantId);
          } catch (_) {
            previousPlant = null; // No encontrado
          }
          
          if (previousPlant != null) {
            // Planta activa anterior aún existe; restaurar
            final idx = _currentTree!.plantas.indexOf(previousPlant);
            _activePlantIndex = idx;
            debugPrint('[PlantController] ✅ FIX 2b: Restored active plant: ${previousPlant.id} (instanceId=$previousActivePlantId, idx=$idx)');
          } else {
            // Planta anterior fue eliminada; fallback a siguiente disponible
            debugPrint('[PlantController] ⚠️ FIX 2b: Previous active plant (ID=$previousActivePlantId) was deleted; fallback to next available');
            _fallbackToNextAvailablePlant();
          }
        }
      }
      
      notifyListeners();
      debugPrint('[PlantController] ✅ Import desde Unity aplicado.');
      return true;
    } catch (e) {
      debugPrint('[PlantController] ❌ Error importando desde Unity: $e');
      return false;
    }
  }

  /// FIX 2c: Fallback helper - encuentra la siguiente planta desbloqueada y viva
  /// cuando la planta activa anterior fue eliminada durante el sync.
  void _fallbackToNextAvailablePlant() {
    final plants = _currentTree?.plantas
        .where((p) => p.desbloqueada && p.estado.fase != 'muerto')
        .toList() ?? [];
    
    if (plants.isEmpty) {
      _activePlantIndex = 0;
      debugPrint('[PlantController] ⚠️ FIX 2c: No plants available; setting index to 0 (activePlant getter will return null)');
      return;
    }
    
    final nextPlant = plants.first;
    final idx = _currentTree!.plantas.indexOf(nextPlant);
    _activePlantIndex = idx;
    debugPrint('[PlantController] ✅ FIX 2c: Fallback: switched to plant ${nextPlant.id} (idx=$idx, instanceId=${nextPlant.instanceId})');
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
          fertilizante: p.fertilizer.toInt(),
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
        fertilizante: TreeRecurso(cantidad: user.resources.fertilizerAmount),
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
        isDead: p.estado.fase == 'muerto',
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

  // ── Cooldowns de Minijuegos ─────────────────────────────────────────────────

  /// Carga los timestamps de cooldown desde SharedPreferences.
  Future<void> _loadCooldowns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      final sunStr = prefs.getString(_cooldownSunKey);
      final waterStr = prefs.getString(_cooldownWaterKey);
      final compostStr = prefs.getString(_cooldownCompostKey);

      _lastSunGameTime = sunStr != null ? DateTime.tryParse(sunStr) : null;
      _lastWaterGameTime = waterStr != null ? DateTime.tryParse(waterStr) : null;
      _lastCompostGameTime = compostStr != null ? DateTime.tryParse(compostStr) : null;

      debugPrint('[Cooldowns] Sun: $_lastSunGameTime, Water: $_lastWaterGameTime, Compost: $_lastCompostGameTime');
    } catch (e) {
      debugPrint('[Cooldowns] Error al cargar: $e');
    }
  }

  /// Guarda los timestamps de cooldown en SharedPreferences.
  Future<void> _saveCooldowns() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_lastSunGameTime != null) {
        await prefs.setString(_cooldownSunKey, _lastSunGameTime!.toIso8601String());
      }
      if (_lastWaterGameTime != null) {
        await prefs.setString(_cooldownWaterKey, _lastWaterGameTime!.toIso8601String());
      }
      if (_lastCompostGameTime != null) {
        await prefs.setString(_cooldownCompostKey, _lastCompostGameTime!.toIso8601String());
      }
    } catch (e) {
      debugPrint('[Cooldowns] Error al guardar: $e');
    }
  }

  /// Retorna true si el minijuego del Sol está disponible (pasó el cooldown).
  bool canPlaySunGame() {
    if (_lastSunGameTime == null) return true;
    return DateTime.now().difference(_lastSunGameTime!) >= sunGameCooldown;
  }

  /// Retorna true si el minijuego del Agua está disponible (pasó el cooldown).
  bool canPlayWaterGame() {
    if (_lastWaterGameTime == null) return true;
    return DateTime.now().difference(_lastWaterGameTime!) >= waterGameCooldown;
  }

  /// Retorna true si el minijuego de Composta está disponible (pasó el cooldown).
  bool canPlayCompostGame() {
    if (_lastCompostGameTime == null) return true;
    return DateTime.now().difference(_lastCompostGameTime!) >= compostGameCooldown;
  }

  /// Retorna el tiempo restante de cooldown del Sol, o null si está disponible.
  Duration? getSunGameRemainingCooldown() {
    if (_lastSunGameTime == null) return null;
    final elapsed = DateTime.now().difference(_lastSunGameTime!);
    final remaining = sunGameCooldown - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  /// Retorna el tiempo restante de cooldown del Agua, o null si está disponible.
  Duration? getWaterGameRemainingCooldown() {
    if (_lastWaterGameTime == null) return null;
    final elapsed = DateTime.now().difference(_lastWaterGameTime!);
    final remaining = waterGameCooldown - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  /// Retorna el tiempo restante de cooldown de Composta, o null si está disponible.
  Duration? getCompostGameRemainingCooldown() {
    if (_lastCompostGameTime == null) return null;
    final elapsed = DateTime.now().difference(_lastCompostGameTime!);
    final remaining = compostGameCooldown - elapsed;
    return remaining.isNegative ? null : remaining;
  }

  /// Registra que el usuario completó el minijuego del Sol y guarda en SharedPreferences.
  void playSunGame() {
    _lastSunGameTime = DateTime.now();
    _saveCooldowns();
    notifyListeners();
  }

  /// Registra que el usuario completó el minijuego del Agua y guarda en SharedPreferences.
  void playWaterGame() {
    _lastWaterGameTime = DateTime.now();
    _saveCooldowns();
    notifyListeners();
  }

  /// Registra que el usuario completó el minijuego de Composta y guarda en SharedPreferences.
  void playCompostGame() {
    _lastCompostGameTime = DateTime.now();
    _saveCooldowns();
    notifyListeners();
  }

  /// Formatea la duración restante para mostrar al usuario (ej: "9:32" o "Listo").
  String formatRemainingCooldown(Duration? duration) {
    if (duration == null) return 'Listo';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ── Overlay Debounce Guards (Prevent Double-Tap) ────────────────────────────

  /// Checks and sets Sun overlay debounce guard.
  /// Returns true if overlay can be launched (not already active).
  /// Returns false if overlay is already active (debounced).
  bool canLaunchSunOverlay() {
    if (_sunOverlayActive) {
      debugPrint('[PlantController] ℹ️ Sun overlay already active; ignoring tap');
      return false;
    }
    _sunOverlayActive = true;
    debugPrint('[PlantController] 🟡 Sun overlay guard: ACTIVE');
    return true;
  }

  /// Resets Sun overlay debounce guard when overlay closes.
  void resetSunOverlay() {
    _sunOverlayActive = false;
    debugPrint('[PlantController] 🟡 Sun overlay guard: RESET');
  }

  /// Checks and sets Water overlay debounce guard.
  /// Returns true if overlay can be launched (not already active).
  /// Returns false if overlay is already active (debounced).
  bool canLaunchWaterOverlay() {
    if (_waterOverlayActive) {
      debugPrint('[PlantController] ℹ️ Water overlay already active; ignoring tap');
      return false;
    }
    _waterOverlayActive = true;
    debugPrint('[PlantController] 💧 Water overlay guard: ACTIVE');
    return true;
  }

  /// Resets Water overlay debounce guard when overlay closes.
  void resetWaterOverlay() {
    _waterOverlayActive = false;
    debugPrint('[PlantController] 💧 Water overlay guard: RESET');
  }

  /// Checks and sets Compost overlay debounce guard.
  /// Returns true if overlay can be launched (not already active).
  /// Returns false if overlay is already active (debounced).
  bool canLaunchCompostOverlay() {
    if (_compostOverlayActive) {
      debugPrint('[PlantController] ℹ️ Compost overlay already active; ignoring tap');
      return false;
    }
    _compostOverlayActive = true;
    debugPrint('[PlantController] 🟤 Compost overlay guard: ACTIVE');
    return true;
  }

  /// Resets Compost overlay debounce guard when overlay closes.
  void resetCompostOverlay() {
    _compostOverlayActive = false;
    debugPrint('[PlantController] 🟤 Compost overlay guard: RESET');
  }
}