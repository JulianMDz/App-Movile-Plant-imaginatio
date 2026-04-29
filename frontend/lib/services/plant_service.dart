import '../models/models.dart';
import 'local_storage_service.dart';

class PlantService {
  final LocalStorageService _storage = LocalStorageService();
  static const double maxHealth = 100.0;

  // Requisitos por planta y stage (igual que tu STAGE_REQUIREMENTS en Python)
  static final Map<String, Map<String, double>> stageRequirements = {
    '${PlantType.solar.name}_${PlantStage.seed.name}': {'sun': 6, 'water': 2},
    '${PlantType.solar.name}_${PlantStage.bush.name}': {'sun': 8, 'water': 4},
    '${PlantType.solar.name}_${PlantStage.tree.name}': {'sun': 10, 'water': 6},
    // Añadir el resto (xerofito, templado, etc.) según tu backend
  };

  static final Map<PlantStage, double> fertilizerToEvolve = {
    PlantStage.seed: 2,
    PlantStage.bush: 4,
    PlantStage.tree: 6,
  };

  Future<PlantState?> applyWater(String plantId) async {
    return _applyResource(plantId, 'water');
  }

  Future<PlantState?> applySun(String plantId) async {
    return _applyResource(plantId, 'sun');
  }

  Future<PlantState?> _applyResource(String plantId, String resourceType) async {
    final userId = await _storage.getCurrentSession();
    if (userId == null) return null;

    final user = await _storage.getUser(userId);
    if (user == null) return null;

    final plantIndex = user.plants.indexWhere((p) => p.plantId == plantId);
    if (plantIndex == -1) return null;

    PlantState plant = user.plants[plantIndex];

    if (plant.isDead || plant.isEnt) return plant;

    // Verificar si el usuario tiene el recurso y descontarlo
    if (resourceType == 'water') {
      if (user.resources.waterAmount < 1) throw Exception("No tienes suficiente agua");
      user.resources.waterAmount -= 1;
      plant.water += 1;
    } else if (resourceType == 'sun') {
      if (user.resources.sunAmount < 1) throw Exception("No tienes suficiente sol");
      user.resources.sunAmount -= 1;
      plant.sun += 1;
    }

    plant.health = (plant.health + 5).clamp(0, maxHealth).toDouble();
    plant.lastInteraction = DateTime.now().toUtc();

    // Check Evolution
    plant = _checkEvolution(plant);
    user.plants[plantIndex] = plant;

    await _storage.saveUser(user);
    return plant;
  }

  PlantState _checkEvolution(PlantState plant) {
    if (plant.isDead || plant.isEnt) return plant;

    final key = '${plant.plantType.name}_${plant.stage.name}';
    final reqs = stageRequirements[key];
    final fertNeeded = fertilizerToEvolve[plant.stage];

    if (reqs == null || fertNeeded == null) return plant;

    if (plant.sun >= reqs['sun']! && plant.water >= reqs['water']! && plant.fertilizer >= fertNeeded) {
      if (plant.stage == PlantStage.seed) plant.stage = PlantStage.bush;
      else if (plant.stage == PlantStage.bush) plant.stage = PlantStage.tree;
      else if (plant.stage == PlantStage.tree) plant.stage = PlantStage.ent;
      
      // Resetear recursos
      plant.sun = 0; plant.water = 0; plant.fertilizer = 0;
      plant.health = maxHealth;
    }
    
    // Actualizar recursos faltantes
    plant.sourcesNextState = getSourcesNextState(plant);
    return plant;
  }

  SourcesNextState getSourcesNextState(PlantState plant) {
    if (plant.isEnt || plant.isDead) return SourcesNextState(sun: 0, water: 0, fertilizer: 0);
    
    final key = '${plant.plantType.name}_${plant.stage.name}';
    final reqs = stageRequirements[key] ?? {'sun': 0, 'water': 0};
    final fertNeeded = fertilizerToEvolve[plant.stage] ?? 0;

    return SourcesNextState(
      sun: (reqs['sun']! - plant.sun).clamp(0, double.infinity).toDouble(),
      water: (reqs['water']! - plant.water).clamp(0, double.infinity).toDouble(),
      fertilizer: (fertNeeded - plant.fertilizer).clamp(0, double.infinity).toDouble(),
    );
  }
}