from pydantic import BaseModel
from schemas.resources import UserResources

class PlantSummary(BaseModel):
    plant_id: str
    plant_name: str
    plant_type: str
    stage: str
    is_ent: bool

class UserRegisterRequest(BaseModel):
    username: str

class UserRegisterResponse(BaseModel):
    user_id: str
    username: str
    unlocked_plants: list[str]
    message: str

class AddPlantRequest(BaseModel):
    plant_type: str

class UserInventoryResponse(BaseModel):
    user_id: str
    username: str
    plants: list[PlantSummary]
    has_ent: bool

class UserResourcesResponse(BaseModel):
    user_id: str
    resources: UserResources

class SyncPlantsRequest(BaseModel):
    plants: list[PlantSummary]