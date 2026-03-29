from fastapi import APIRouter, HTTPException

from schemas.plant import PlantActionRequest, PlantActionResponse, PlantStage
from services import plant_service

router = APIRouter (
    prefix="/plant",
    tags=["plants"]
)

def _validate_plant(request: PlantActionRequest):
    """"Validación básica para asegurar que el estado de la planta es coherente antes de aplicar cualquier acción."""
    if request.plant_state.is_dead:
        raise HTTPException(
            status_code=400,
            detail="Plant is dead and cannot perform actions"
        )
    if request.plant_state.stage == PlantStage.ENT:
        raise HTTPException(
            status_code=400,
            detail="La planta es un Ent — solo puede participar en combates"
        )

@router.post("/water" , response_model=PlantActionResponse)
def water_plant(request: PlantActionRequest):
    _validate_plant(request)
    plant = plant_service.update_passive_state(request.plant_state)
    plant = plant_service.apply_water(plant)
    plant, evolved = plant_service.check_evolution(plant)

    return PlantActionResponse(
        plant_id=request.plant_id,
        plant_state=plant,
        evolved=evolved,
        message="Planta regada exitosamente" 
        
    )

@router.post("/sun" , response_model=PlantActionResponse)
def apply_sun(request: PlantActionRequest):
    _validate_plant(request)
    plant = plant_service.update_passive_state(request.plant_state)
    plant = plant_service.apply_sun(plant)
    plant, evolved = plant_service.check_evolution(plant)

    return PlantActionResponse(
        plant_id=request.plant_id,
        plant_state=plant, 
        evolved=evolved,
        message="Planta expuesta al sol exitosamente"
        
    )

@router.post("/fertilize" , response_model=PlantActionResponse)
def apply_fertilizer(request: PlantActionRequest):
    _validate_plant(request)
    plant = plant_service.update_passive_state(request.plant_state)
    plant = plant_service.apply_fertilizer(plant)
    plant, evolved = plant_service.check_evolution(plant)

    return PlantActionResponse(
        plant_id=request.plant_id,
        plant_state=plant, 
        evolved=evolved,
        message="Planta fertilizada exitosamente" 
    )

@router.post("/evolve" , response_model=PlantActionResponse)
def evolve_plant(request: PlantActionRequest):
    _validate_plant(request)
    plant = plant_service.update_passive_state(request.plant_state)
    plant, evolved = plant_service.check_evolution(plant)
    return PlantActionResponse(
        plant_id=request.plant_id,
        plant_state=plant,
        evolved=evolved,
        message="Evolución exitosa" if evolved else "No se cuentan con los recursos necesarios para evolucionar"
    )