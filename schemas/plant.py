from pydantic import BaseModel
from enum import Enum
from datetime import datetime

# Tipo de plantas dados por la tabla de tipos (provisionales)
class PlantType(str, Enum):
    hidro = "hidro"
    solar = "solar"
    xerofito = "xerofito"
    montaña = "montaña"
    Templado = "templado"

# Recursos para que la planta logre cambiar de estado
class SourcesNextState(BaseModel):
    water: int
    sun: int
    prune: int


# PlantBase      → campos comunes (los que siempre existen)
# PlantCreate    → lo que Flutter manda al crear (hereda Base)
# PlantResponse  → lo que el servidor devuelve (hereda Base + agrega id)

# Modelo base para el estado de la planta
class PlantStateBase(BaseModel):
    plant_state: str
    health: int
    sun: int
    water: int
    prune: int
    time_without_care: datetime
    sources_next_state: SourcesNextState

# Modelo para la respuesta del estado de la planta
class PlantStateResponse(PlantStateBase):
    id: int
    plant_id: int

    class Config:
        from_attributes = True

# Modelo base para la planta
class PlantBase (BaseModel):
    plant_name: str
    plant_type: PlantType

class PlantCreate(PlantBase):
    pass

class PlantResponse(PlantBase):
    id: int
    state:PlantStateResponse

    class config:
        from_attributes = True