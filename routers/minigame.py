from fastapi import APIRouter
from datetime import datetime, timedelta
from schemas.minigame import (
    SunMinigameRequest,
    WaterMinigameRequest,
    CompostMinigameRequest,
    MinigameResponse
)

router = APIRouter(
    prefix="/minigame",
    tags=["minigame"]
)

@router.post("/sun", response_model=MinigameResponse)
def play_sun(request: SunMinigameRequest):
    return MinigameResponse(
        plant_id=request.plant_id,
        reward_type="sun",
        reward_amount=0,
        next_available=datetime.now() + timedelta(minutes=10),
        message="Minijuego de sol completado"
    )

@router.post("/water", response_model=MinigameResponse)
def play_water(request: WaterMinigameRequest):
    return MinigameResponse(
        plant_id=request.plant_id,
        reward_type="water",
        reward_amount=0,
        next_available=datetime.now() + timedelta(minutes=10),
        message="Minijuego de agua completado"
    )

@router.post("/compost", response_model=MinigameResponse)
def play_compost(request: CompostMinigameRequest):
    return MinigameResponse(
        plant_id=request.plant_id,
        reward_type="fertilizer",
        reward_amount=0,
        next_available=datetime.now() + timedelta(minutes=10),
        message="Minijuego de composta completado"
    )