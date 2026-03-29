from fastapi import FastAPI
from routers import plants, minigame, resources

app = FastAPI(
    title="Imaginatio Plant Backend",
    description="Motor lógico para el cuidado de plantas virtuales",
    version="2.0.0"
)

app.include_router(plants.router)
app.include_router(minigame.router)
app.include_router(resources.router)

@app.get("/")
def root():
    return {
        "status": "ok",
        "message": "Imaginatio Plant Backend v2.0.0"
    }