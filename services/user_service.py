import json
import os
from uuid import uuid4
from datetime import datetime, timezone
from fastapi import HTTPException
from schemas.user import (
    UserRegisterRequest,
    UserRegisterResponse,
    UserInventoryResponse,
    PlantSummary,
    SyncPlantsRequest,
    AddPlantRequest,
    UserResourcesResponse
)
from schemas.resources import UserResources, ResourceType

DATA_DIR = "data/users"
DEFAULT_PLANTS = ["pasto"]
DEFAULT_RESOURCES = {
    "sun_amount": 0,
    "water_amount": 0,
    "fertilizer_amount": 0,
    "compost_amount": 0
}

def _get_user_path(user_id: str) -> str:
    return os.path.join(DATA_DIR, f"{user_id}.json")

def _read_user(user_id: str) -> dict:
    path = _get_user_path(user_id)
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    with open(path, "r") as f:
        return json.load(f)

def _write_user(data: dict):
    os.makedirs(DATA_DIR, exist_ok=True)
    path = _get_user_path(data["user_id"])
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
def register_user(request: UserRegisterRequest) -> UserRegisterResponse:
    user_id = str(uuid4())[:8]
    
    # Planta default creada automáticamente
    default_plant = {
        "plant_id": str(uuid4())[:8],
        "plant_name": "Pasto",
        "plant_type": "pasto",
        "stage": "seed",
        "is_ent": False
    }
    
    data = {
        "user_id": user_id,
        "username": request.username,
        "unlocked_plants": DEFAULT_PLANTS,
        "resources": DEFAULT_RESOURCES,
        "plants": [default_plant],    # ← planta default
        "registered_at": datetime.now(timezone.utc).isoformat()
    }
    _write_user(data)
    return UserRegisterResponse(
        user_id=user_id,
        username=request.username,
        unlocked_plants=DEFAULT_PLANTS,
        message=f"Bienvenido {request.username} — tu planta pasto está lista"
    )

def get_resources(user_id: str) -> UserResourcesResponse:
    data = _read_user(user_id)
    return UserResourcesResponse(
        user_id=user_id,
        resources=UserResources(**data["resources"])
    )

def use_resource(user_id: str, resource_type: ResourceType, amount: int) -> UserResourcesResponse:
    data = _read_user(user_id)
    resources = data["resources"]

    field = f"{resource_type.value}_amount"
    if resources[field] < amount:
        raise HTTPException(
            status_code=400,
            detail=f"No tienes suficiente {resource_type.value} — tienes {resources[field]}"
        )
    resources[field] -= amount
    data["resources"] = resources
    _write_user(data)
    return UserResourcesResponse(
        user_id=user_id,
        resources=UserResources(**resources)
    )

def add_resource(user_id: str, resource_type: str, amount: int):
    data = _read_user(user_id)
    field = f"{resource_type}_amount"
    if field in data["resources"]:
        data["resources"][field] += amount
    _write_user(data)

def sync_plants(user_id: str, request: SyncPlantsRequest):
    data = _read_user(user_id)
    data["plants"] = [p.model_dump() for p in request.plants]
    _write_user(data)
    return {"message": "Plantas sincronizadas"}

def get_inventory(user_id: str) -> UserInventoryResponse:
    data = _read_user(user_id)
    plants = [PlantSummary(**p) for p in data.get("plants", [])]
    has_ent = any(p.is_ent for p in plants)
    return UserInventoryResponse(
        user_id=data["user_id"],
        username=data["username"],
        plants=plants,
        has_ent=has_ent
    )

def add_plant(user_id: str, request: AddPlantRequest):
    data = _read_user(user_id)
    if request.plant_type not in data["unlocked_plants"]:
        data["unlocked_plants"].append(request.plant_type)
        _write_user(data)
    return {
        "unlocked_plants": data["unlocked_plants"],
        "message": f"Planta {request.plant_type} desbloqueada"
    }