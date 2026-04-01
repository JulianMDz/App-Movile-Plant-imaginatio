from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import plants, minigame, resources, users

app = FastAPI(
    title="Imaginatio Plant Backend",
    description="Motor lógico para el cuidado de plantas virtuales",
    version="2.0.0"
)

app.include_router(users.router)
app.include_router(plants.router)
app.include_router(minigame.router)
app.include_router(resources.router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # acepta cualquier origen
    allow_methods=["*"],      # acepta GET, POST, etc
    allow_headers=["*"],      # acepta cualquier header
)
    
@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "Imaginatio Plant Backend v2.0.0"
    }