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

  // ── Cooldowns de Minijuegos (persisten entre sesiones via SharedPreferences) ─
  static const Duration sunGameCooldown = Duration(seconds: 10);
  static const Duration waterGameCooldown = Duration(seconds: 10);
  static const Duration compostGameCooldown = Duration(seconds: 10);

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

  // Flags para notify de animaciones

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
  bool _showDeathAnimation = false;
  bool _showCriticalAnimation = false;
  bool _showDangerAnimation = false;
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

      if (_currentTree != null) {
        _ensureDefaultPlant();
        await applyPassiveDecay();
        await saveTree();
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
      await saveTree();                  // persiste el tree con la planta pasto inicial
      await _loadCooldowns();            // cargar cooldowns desde SharedPreferences
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

    if (_currentTree!.plantas.isNotEmpty) return;

    final plantsToCreate = [
      ('pasto', 'semilla'),
      ('aliso', 'semilla'),
      ('aliso', 'semilla'),
      ('cedrillo', 'semilla'),
      ('cucharo', 'semilla'),
      ('alcaparro grande', 'semilla'),
      ('espino', 'semilla'),
      ('roble', 'semilla'),
      ('manzano', 'semilla'),
    ];

    for (int i = 0; i < plantsToCreate.length; i++) {
      final (id, fase) = plantsToCreate[i];
      final plant = TreePlanta(
        id: id,
        instanceId: '${_uuid.v4()}_$i',
        subid: id,
        desbloqueada: true,
        estado: TreeEstado(fase: fase),
        recursosAplicados: TreeRecursosAplicados(sol: 3, agua: 3, fertilizante: 1),
      );
      _currentTree!.plantas.add(plant);
    }
    debugPrint('[PlantController] 🌱 ${plantsToCreate.length} plantas creadas para testing de selección');
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
  Future<void> applyPassiveDecay() async {
    if (_currentTree == null) return;

    final plant = activePlant;
    if (plant == null) return;

    // Si la planta está en fase ENT, no aplicar decay (ya está madura)
    if (plant.estado.fase == 'ent') return;

    final now = DateTime.now().toUtc();
    final lastInteraction = await _authStorage.getPlantLastInteraction(plant.instanceId);

    final minutesPassed = now.difference(lastInteraction).inMinutes;
    if (minutesPassed < _decayIntervalMin) return;

    final intervals = minutesPassed ~/ _decayIntervalMin;

    plant.recursosAplicados.agua =
        (plant.recursosAplicados.agua - intervals).clamp(0, 9999);
    plant.recursosAplicados.sol =
        (plant.recursosAplicados.sol - intervals).clamp(0, 9999);

    if (plant.recursosAplicados.agua <= 0 || plant.recursosAplicados.sol <= 0) {
      plant.estado.fase = 'muerto';
      _showDeathAnimation = true;
      debugPrint(
        '[PlantController] 🚨 Planta activa ${plant.id} ha muerto por falta de recursos.'
      );
    } else {
      final sol = plant.recursosAplicados.sol;
      final agua = plant.recursosAplicados.agua;
      if (sol <= 2 || agua <= 2) {
        _showCriticalAnimation = true;
      } else if (sol <= 4 || agua <= 4) {
        _showDangerAnimation = true;
      }
    }

    final newInteraction = lastInteraction.add(
      Duration(minutes: intervals * _decayIntervalMin),
    );
    await _authStorage.savePlantLastInteraction(plant.instanceId, newInteraction);
    await saveTree(); // Persistir cambios del decay

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
  TreePlanta? get activePlant {
    if (_currentTree == null || _currentTree!.plantas.isEmpty) return null;
    final plants = _currentTree!.plantas.where((p) => p.desbloqueada && p.estado.fase != 'muerto').toList();
    if (plants.isEmpty) return null;
    // Validar que el índice sea válido para la lista filtrada
    if (_activePlantIndex < 0 || _activePlantIndex >= plants.length) {
      // Si el índice no es válido, usar la primera planta disponible
      _activePlantIndex = 0;
    }
    return plants[_activePlantIndex];
  }

  /// Retorna la planta por índice directo (para inventario).
  TreePlanta? getPlantByIndex(int index) {
    if (_currentTree == null || index < 0 || index >= _currentTree!.plantas.length) {
      return null;
    }
    return _currentTree!.plantas[index];
  }

  /// Establece la planta activa por índice.
  void setActivePlant(int index) {
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
      _checkEvolution(plant);
      saveTree(); // Persistir cambios
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
      _checkEvolution(plant);
      saveTree(); // Persistir cambios
    }
    notifyListeners();
    return true;
  }

  /// Gasta [amount] unidades de fertilizante del inventario.
  /// Añade [amount] fertilizante a la planta activa.
  bool spendCompost({int amount = 1}) {
    if (_currentTree == null) return false;
    if (_currentTree!.recursos.fertilizante.cantidad < amount) return false;
    _currentTree!.recursos.fertilizante.cantidad -= amount;
    _currentUser?.resources.fertilizerAmount -= amount;
    final plant = activePlant;
    if (plant != null) {
      plant.recursosAplicados.fertilizante += amount;
      _checkEvolution(plant);
      saveTree(); // Persistir cambios
    }
    notifyListeners();
    return true;
  }

  // ── Sistema de Evolución ─────────────────────────────────────────────────────

  /// Retorna true si hay animación de evolución pendientes
  bool get showEvolutionAnimation => _showEvolutionAnimation;
  bool get showDeathAnimation => _showDeathAnimation;
  bool get showCriticalAnimation => _showCriticalAnimation;
  bool get showDangerAnimation => _showDangerAnimation;

  /// Limpia los flags de animación
  void clearAnimationFlags() {
    _showEvolutionAnimation = false;
    _showDeathAnimation = false;
    _showCriticalAnimation = false;
    _showDangerAnimation = false;
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
      _showDeathAnimation = true;
      debugPrint('[PlantController] 💀 Planta murió');
    } else if (sol <= 2 || agua <= 2) {
      _showCriticalAnimation = true;
    } else if (sol <= 4 || agua <= 4) {
      _showDangerAnimation = true;
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
      _showEvolutionAnimation = true;
      debugPrint('[PlantController] 🌱 Planta evolucionó automáticamente a: $nextFase');
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

  /// Avanza el tiempo de todas las plantas por [minutes] minutos (para debug).
  Future<void> debugAdvanceTime(int minutes) async {
    final plants = _currentTree?.plantas ?? [];
    for (final plant in plants) {
      final lastInteraction = await _authStorage.getPlantLastInteraction(plant.instanceId);
      final newTime = lastInteraction.add(Duration(minutes: minutes));
      await _authStorage.savePlantLastInteraction(plant.instanceId, newTime);
    }
    debugPrint('[Debug] Tiempo avanzadas $minutes minutos');
  }

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
        await applyPassiveDecay();
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
}