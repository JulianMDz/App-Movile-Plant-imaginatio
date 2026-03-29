from pydantic import BaseModel 
from enum import Enum

class ResourceType(str, Enum):
    sun = "sun"
    water = "water"
    fertilizer = "fertilizer"

class UserResources(BaseModel):
    sun_amount: int = 0
    water_amount: int = 0
    fertilizer_amount: int = 0

class ResourceUseRequest(BaseModel):
    user_resources: UserResources
    resource_type: ResourceType
    amount: int = 1

class ResourceUseResponse(BaseModel):
    user_resources: UserResources
    success: bool
    message: str

