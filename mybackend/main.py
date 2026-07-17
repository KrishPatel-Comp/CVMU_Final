from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from auth import router as auth_router
from categories import router as categories_router
from transactions import router as transactions_router
from analytics_router import router as analytics_router

app = FastAPI()

app.include_router(auth_router, prefix="/auth", tags=["Auth"])
# These routers already define their own `prefix` (and tags) inside each module.
app.include_router(categories_router)
app.include_router(transactions_router)
app.include_router(analytics_router)

app.add_middleware(
    CORSMiddleware,
    # In development we allow all origins so Flutter Web / tools
    # can call the API without CORS issues.
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {"message": "Backend is working"}