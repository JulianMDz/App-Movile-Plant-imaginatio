from fastapi import APIRouter 

router = APIRouter (
    prefix="/plant",
    tags=["plants"]
)

@router.get("/{plant_id}")
def get_plant(plant_id: int):
    return {"plant_id: ": plant_id, "name": "Pasto", "type": "Cesped"}

@router.get("/{plant_id}/state")
def get_plant_state(plant_id: int):
    return{
        "plant_id": plant_id,
        "plant_state": "healthy",
        "health": 100,
        "sun": 50,
        "water": 50,
        "prune": 50,
        "time_without_care": "2 days",
    }

@router.post("/{plant_id}/water")
def water_plant(plant_id: int):
    return {"message": f"Plant {plant_id} watered successfully"}

@router.post("/{plant_id}/prune")
def prune_plant(plant_id: int):
    return {"message":f"Plant {plant_id} pruned successfully"}

@router.post("/{plant_id}/sun")
def sun_plant(plant_id: int):
    return {"message":f"Plant {plant_id} collectedsun successfully"}
