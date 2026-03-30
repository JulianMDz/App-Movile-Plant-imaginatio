from fastapi import APIRouter
from schemas.minigame import (
    SunMinigameRequest,
    WaterMinigameRequest,
    CompostMinigameRequest,
    MinigameResponse
)
from services import minigame_service

router = APIRouter(
    prefix="/minigame",
    tags=["minigame"]
)

@router.post("/sun", response_model=MinigameResponse)
def play_sun(request: SunMinigameRequest):
    return minigame_service.play_sun(request)

@router.post("/water", response_model=MinigameResponse)
def play_water(request: WaterMinigameRequest):
    return minigame_service.play_water(request)

@router.post("/compost", response_model=MinigameResponse)
def play_compost(request: CompostMinigameRequest):
    return minigame_service.play_compost(request)