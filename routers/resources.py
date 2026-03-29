from fastapi import APIRouter
from schemas.resources import ResourceUseRequest, ResourceUseResponse
from services.resource_service import use_resource

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
        message=f"Usaste {request.amount} {request.resource_type}"
    )