from fastapi import FastAPI
from routers import plants

app =  FastAPI(title="Plant Backend API", description="API for Plamt Backend", version="1.0.0")

app.include_router(plants.router)

@app.get("/")
def root():
    return{"satatus": "ok", "message":"Plant API running " }

