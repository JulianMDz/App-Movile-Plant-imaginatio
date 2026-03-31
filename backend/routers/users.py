from fastapi import APIRouter
from schemas.user import (
    UserRegisterRequest,
    UserRegisterResponse,
    UserInventoryResponse,
    UserResourcesResponse,
    SyncPlantsRequest,
    AddPlantRequest
)
from schemas.resources import ResourceUseRequest
from services import user_service

router = APIRouter(
    prefix="/user",
    tags=["users"]
)

# Unity + Flutter
@router.post("/register", response_model=UserRegisterResponse)
def register_user(request: UserRegisterRequest):
    return user_service.register_user(request)

# Unity
@router.get("/{user_id}/inventory", response_model=UserInventoryResponse)
def get_inventory(user_id: str):
    return user_service.get_inventory(user_id)

# Flutter
@router.get("/{user_id}/resources", response_model=UserResourcesResponse)
def get_resources(user_id: str):
    return user_service.get_resources(user_id)

@router.post("/{user_id}/resources/use", response_model=UserResourcesResponse)
def use_resource(user_id: str, request: ResourceUseRequest):
    return user_service.use_resource(
        user_id,
        request.resource_type,
        request.amount
    )

@router.post("/{user_id}/plants/sync")
def sync_plants(user_id: str, request: SyncPlantsRequest):
    return user_service.sync_plants(user_id, request)

@router.post("/{user_id}/plants/unlock")
def add_plant(user_id: str, request: AddPlantRequest):
    return user_service.add_plant(user_id, request)