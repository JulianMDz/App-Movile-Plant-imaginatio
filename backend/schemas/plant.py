from pydantic import BaseModel
from enum import Enum
from datetime import datetime
from typing import Optional

class PlantType(str, Enum):
    hidro = "hidro"
    solar = "solar"
    xerofito = "xerofito"
    montana = "montana"
    templado = "templado"
    pasto = "pasto"

class PlantStage(str, Enum):
    SEED = "seed"
    BUSH = "bush"
    TREE = "tree"
    ENT = "ent"

class SourcesNextState(BaseModel):
    sun: float
    water: float
    fertilizer: float

class PlantState(BaseModel):
    plant_name: str
    plant_type: PlantType
    stage: PlantStage = PlantStage.SEED
    health: float = 100
    sun: float = 0
    water: float = 0
    fertilizer: float = 0
    is_dead: bool = False
    last_interaction: datetime
    sources_next_state: SourcesNextState

class PlantActionRequest(BaseModel):
    user_id: str
    plant_id: str
    plant_state: PlantState

class PlantActionResponse(BaseModel):
    plant_id: str
    plant_state: PlantState
    evolved: bool = False
    message: str