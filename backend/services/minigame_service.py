from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from schemas.minigame import (
    MinigameResponse,
    SunMinigameRequest,
    WaterMinigameRequest,
    CompostMinigameRequest
)

COOLDOWN_MINUTES = 10
MAX_CLICKS_PER_SECOND = 12
COMPOST_TO_FERTILIZER = 4

def _check_cooldown(last_collected: datetime | None):
    if last_collected is None:
        return
    next_available = last_collected + timedelta(minutes=COOLDOWN_MINUTES)
    if datetime.now(timezone.utc) < next_available:
        raise HTTPException(
            status_code=429,
            detail=f"Minijuego en cooldown. Disponible a las {next_available.strftime('%H:%M:%S')}"
        )
    
def _validate_clicks(clicks: int, duration_seconds: float):
    if duration_seconds <= 0:
        raise HTTPException(status_code=400, detail="Duración del minijuego debe ser mayor a 0 segundos")
    clicks_per_second = clicks / duration_seconds
    if clicks_per_second > MAX_CLICKS_PER_SECOND:
        raise HTTPException(
            status_code=400,
            detail=f"Velocidad de clicks imposible: {clicks_per_second:.1f}/s — posible trampa"
        )

def play_sun(request: SunMinigameRequest) -> MinigameResponse:
    _check_cooldown(request.last_collected)
    _validate_clicks(request.clicks, request.duration_seconds)
    reward = request.clicks # 1 sol por click, sin bonus por duración
    return MinigameResponse(
        plant_id=request.plant_id,
        reward_type="sun",
        reward_amount=reward,
        next_available=datetime.now(timezone.utc) + timedelta(minutes=COOLDOWN_MINUTES),
        message=f"Obtuviste {reward} sol"
    )

def play_water(request: WaterMinigameRequest) -> MinigameResponse:
    _check_cooldown(request.last_collected)
    _validate_clicks(request.clicks, request.duration_seconds)
    # Tabla de recompensas
    if request.clicks >= 50:
        reward = 6
    elif request.clicks >= 35:
        reward = 4
    elif request.clicks >= 25:
        reward = 2
    else:
        reward = 0
    return MinigameResponse(
        plant_id=request.plant_id,
        reward_type="water",
        reward_amount=reward,
        next_available=datetime.now(timezone.utc) + timedelta(minutes=COOLDOWN_MINUTES),
        message=f"Obtuviste {reward} agua"
    )


def play_compost(request: CompostMinigameRequest) -> MinigameResponse:
    _check_cooldown(request.last_collected)
    valid = max(0, request.compost_collected - request.trash_clicked)
    
    # Suma al acumulado
    total_compost = request.current_compost + valid
    
    # Conversión automática
    fertilizer_gained = total_compost // COMPOST_TO_FERTILIZER
    remaining_compost = total_compost % COMPOST_TO_FERTILIZER

    return MinigameResponse(
        plant_id=request.plant_id,
        reward_type="compost",
        reward_amount=valid,
        next_available=datetime.now(timezone.utc) + timedelta(minutes=COOLDOWN_MINUTES),
        message=f"Obtuviste {valid} composta — {fertilizer_gained} fertilizante ganado ({remaining_compost}/3)",
        compost_total=remaining_compost,
        fertilizer_gained=fertilizer_gained
    )