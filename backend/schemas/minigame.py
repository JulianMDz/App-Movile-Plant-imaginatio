from pydantic import BaseModel
from datetime import datetime

class SunMinigameRequest(BaseModel):
    user_id: str
    plant_id: str
    clicks: int
    duration_seconds: float    # tiempo real que duró el minijuego
    last_collected: datetime | None = None

class WaterMinigameRequest(BaseModel):
    useer_id: str
    plant_id: str
    clicks: int
    duration_seconds: float    # debe ser <= 5 segundos
    last_collected: datetime | None = None

class CompostMinigameRequest(BaseModel):
    user_id: str
    plant_id: str
    compost_collected: int     # 0 a 4
    trash_clicked: int         # 0 a 4
    current_compost: int         # cantidad actual de composta del usuario
    last_collected: datetime | None = None

class MinigameResponse(BaseModel):
    plant_id: str
    reward_type: str
    reward_amount: int
    next_available: datetime
    message: str
    compost_total: int = 0      # ← nuevo compost acumulado
    fertilizer_gained: int = 0  # ← fertilizante ganado (0 o 1
