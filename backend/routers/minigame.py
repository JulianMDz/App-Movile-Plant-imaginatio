from fastapi import APIRouter
from schemas.minigame import (
    SunMinigameRequest,
    WaterMinigameRequest,
    CompostMinigameRequest,
    MinigameResponse
)
from services import minigame_service, user_service


router = APIRouter(
    prefix="/minigame",
    tags=["minigame"]
)

@router.post("/sun", response_model=MinigameResponse)
def play_sun(user_id: str, request: SunMinigameRequest):
    result = minigame_service.play_sun(request)
    user_service.add_resource(user_id, "sun", result.reward_amount)
    return result

@router.post("/water", response_model=MinigameResponse)
def play_water(user_id: str, request: WaterMinigameRequest):
    result = minigame_service.play_water(request)
    user_service.add_resource(user_id, "water", result.reward_amount)
    return result

@router.post("/compost", response_model=MinigameResponse)
def play_compost(user_id: str, request: CompostMinigameRequest):
    result = minigame_service.play_compost(request)
    user_service.add_resource(user_id, "compost", result.compost_total)
    user_service.add_resource(user_id, "fertilizer", result.fertilizer_gained)
    return result