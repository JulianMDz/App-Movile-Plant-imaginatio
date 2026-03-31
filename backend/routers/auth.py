from fastapi import APIRouter
from schemas.user import UserCreate, UserLogin, UserRespose, Token

router = APIRouter(
    prefix="/auth",
    tags=["auth"]
)

@router.post("/register", response_model=UserRespose)
def register(user:UserCreate):
    return {"message": f"user {user.username} created successfully"}

@router.post("/login", response_model=Token)
def login(credentials: UserLogin):
    return Token(
        access_token="fake_access_token",
        token_type="bearer"
    )

@router.get("/me", response_model=UserRespose)
def get_me():
    return {"id": 1, "username": "test_user", "email": "test_user@example.com"}