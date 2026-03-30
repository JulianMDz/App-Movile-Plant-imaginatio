from fastapi import APIRouter
from schemas.resources import ResourceUseRequest, ResourceUseResponse, UserResources
from services.resource_service import COMPOST_TO_FERTILIZER, use_resource, convert_compost

router = APIRouter(
    prefix="/user/resources",
    tags=["resources"]
)

@router.post("/use", response_model=ResourceUseResponse)
def use_resource_endpoint(request: ResourceUseRequest):
    resources = use_resource(
        request.user_resources,
        request.resource_type,
        request.amount
    )
    return ResourceUseResponse(
        user_resources=resources,
        success=True,
        message=f"Usaste {request.amount} {request.resource_type.value}"
    )

@router.post("/convert/compost", response_model=ResourceUseResponse)
def convert_compost_endpoint(user_resources: UserResources):
    resources = convert_compost(user_resources)
    return ResourceUseResponse(
        user_resources=resources,
        success=True,
        message=f"Convertiste {COMPOST_TO_FERTILIZER} unidades de composta en 1 unidad de fertilizante"
    )

