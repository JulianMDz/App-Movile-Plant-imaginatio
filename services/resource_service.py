from fastapi import HTTPException
from schemas.resources import UserResources, ResourceType

COMPOST_TO_FERTILIZER = 10

def use_resource(resources: UserResources, resource_type: ResourceType, amount: int) -> UserResources:
    
    if resource_type == ResourceType.water:
        if resources.water_amount < amount:
            raise HTTPException(
                status_code=400,
                detail="No tienes suficiente agua"
            )
        resources.water_amount -= amount
        return resources

    if resource_type == ResourceType.sun:
        if resources.sun_amount < amount:
            raise HTTPException(
                status_code=400,
                detail="No tienes suficiente sol"
            )
        resources.sun_amount -= amount
        return resources

    if resource_type == ResourceType.fertilizer:
        if resources.fertilizer_amount < amount:
            raise HTTPException(
                status_code=400,
                detail="No tienes suficiente fertilizante"
            )
        resources.fertilizer_amount -= amount
        return resources

def convert_compost(resources: UserResources) -> UserResources:
    if resources.compost_amount < COMPOST_TO_FERTILIZER:
        raise HTTPException(
            status_code=400,
            detail="No tienes suficiente composta"
        )
    resources.compost_amount -= COMPOST_TO_FERTILIZER
    resources.fertilizer_amount += 1
    return resources
