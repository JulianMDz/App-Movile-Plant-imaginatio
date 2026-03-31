from datetime import datetime, timedelta, timezone
from schemas.plant import PlantState, PlantStage, PlantType, SourcesNextState

# Constantes
MAX_HEALTH = 100
DEATH_HOURS_THRESHOLD = 72.0
HEALTH_LOSS_PER_HOUR = 100.0 / 72.0
RESOURCE_LOSS_PER_HOUR = 1.0

# Requisitos por tipo y stage (sol, agua)
STAGE_REQUIREMENTS = {
    (PlantType.solar,    PlantStage.SEED): {"sun": 6,  "water": 2},
    (PlantType.solar,    PlantStage.BUSH): {"sun": 8,  "water": 4},
    (PlantType.solar,    PlantStage.TREE): {"sun": 10, "water": 6},
    (PlantType.xerofito, PlantStage.SEED): {"sun": 4,  "water": 2},
    (PlantType.xerofito, PlantStage.BUSH): {"sun": 6,  "water": 4},
    (PlantType.xerofito, PlantStage.TREE): {"sun": 8,  "water": 6},
    (PlantType.templado, PlantStage.SEED): {"sun": 4,  "water": 4},
    (PlantType.templado, PlantStage.BUSH): {"sun": 6,  "water": 6},
    (PlantType.templado, PlantStage.TREE): {"sun": 8,  "water": 8},
    (PlantType.montana,  PlantStage.SEED): {"sun": 2,  "water": 4},
    (PlantType.montana,  PlantStage.BUSH): {"sun": 4,  "water": 6},
    (PlantType.montana,  PlantStage.TREE): {"sun": 6,  "water": 8},
    (PlantType.hidro,    PlantStage.SEED): {"sun": 2,  "water": 6},
    (PlantType.hidro,    PlantStage.BUSH): {"sun": 4,  "water": 8},
    (PlantType.hidro,    PlantStage.TREE): {"sun": 6,  "water": 10},
    (PlantType.pasto, PlantStage.SEED): {"sun": 3, "water": 3},
    (PlantType.pasto, PlantStage.BUSH): {"sun": 5, "water": 5},
    (PlantType.pasto, PlantStage.TREE): {"sun": 7, "water": 7},
}

# Abono necesario por stage (igual para todos los tipos)
FERTILIZER_TO_EVOLVE = {
    PlantStage.SEED: 4,
    PlantStage.BUSH: 6,
    PlantStage.TREE: 8,
}

# Siguiente stage
NEXT_STAGE = {
    PlantStage.SEED: PlantStage.BUSH,
    PlantStage.BUSH: PlantStage.TREE,
    PlantStage.TREE: PlantStage.ENT,
}

def update_passive_state(plant: PlantState) -> PlantState:
    """Calcula pérdida de recursos y salud por tiempo transcurrido"""
    if plant.is_dead or plant.stage == PlantStage.ENT:
        return plant

    now = datetime.now(timezone.utc)

    last = plant.last_interaction
    if last.tzinfo is None:
        last = last.replace(tzinfo=timezone.utc)

    hours_passed = (now - last).total_seconds() / 3600.0

    # Muerte por inactividad
    if hours_passed >= DEATH_HOURS_THRESHOLD:
        plant.is_dead = True
        plant.health = 0
        return plant

    # Pérdida pasiva
    plant.health = max(0, plant.health - HEALTH_LOSS_PER_HOUR * hours_passed)
    plant.water = max(0, plant.water - RESOURCE_LOSS_PER_HOUR * hours_passed)
    plant.sun = max(0, plant.sun - RESOURCE_LOSS_PER_HOUR * hours_passed)

    if plant.health <= 0:
        plant.is_dead = True

    return plant

def get_sources_next_state(plant: PlantState) -> SourcesNextState:
    """Calcula los recursos necesarios para el siguiente stage"""
    
    
    if plant.stage == PlantStage.ENT:
        return SourcesNextState(sun=0, water=0, fertilizer=0)
    
    reqs = STAGE_REQUIREMENTS.get((plant.plant_type, plant.stage))
    fert = FERTILIZER_TO_EVOLVE.get(plant.stage, 0)
    
    if not reqs:
        return SourcesNextState(sun=0, water=0, fertilizer=0)
    
    return SourcesNextState(
        sun=reqs["sun"],
        water=reqs["water"],
        fertilizer=fert
    )

def apply_water(plant: PlantState) -> PlantState:
    """Aplica agua y regenera salud"""
    if plant.is_dead or plant.stage == PlantStage.ENT:
        return plant
    plant.water += 1
    plant.health = min(MAX_HEALTH, plant.health + 5)
    plant.last_interaction = datetime.now(timezone.utc)
    return plant

def apply_sun(plant: PlantState) -> PlantState:
    """Aplica sol y regenera salud"""
    if plant.is_dead or plant.stage == PlantStage.ENT:
        return plant
    plant.sun += 1
    plant.health = min(MAX_HEALTH, plant.health + 5)
    plant.last_interaction = datetime.now(timezone.utc)
    return plant

def apply_fertilizer(plant: PlantState, amount: int) -> PlantState:
    """Aplica fertilizante y regenera bastante salud"""
    if plant.is_dead or plant.stage == PlantStage.ENT:
        return plant
    plant.fertilizer += amount
    plant.health = min(MAX_HEALTH, plant.health + 20)
    plant.last_interaction = datetime.now(timezone.utc)
    return plant

def check_evolution(plant: PlantState) -> tuple[PlantState, bool]:
    """Verifica si la planta puede evolucionar"""
    if plant.is_dead or plant.stage == PlantStage.ENT:
        return plant, False

    reqs = STAGE_REQUIREMENTS.get((plant.plant_type, plant.stage))
    fert_needed = FERTILIZER_TO_EVOLVE.get(plant.stage)

    if not reqs or not fert_needed:
        return plant, False

    can_evolve = (
        plant.sun >= reqs["sun"] and
        plant.water >= reqs["water"] and
        plant.fertilizer >= fert_needed
    )

    if can_evolve:
        plant.sun -= reqs["sun"]
        plant.water -= reqs["water"]
        plant.fertilizer -= fert_needed
        plant.stage = NEXT_STAGE[plant.stage]
        plant.health = MAX_HEALTH
        return plant, True

    return plant, False