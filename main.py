from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

app = FastAPI(
    title="NickCloud API",
    description="A small FastAPI service that showcases the cloud engineering around it.",
    version="1.0.0",
)
STATIC_DIR = Path(__file__).resolve().parent / "static"
ROOT_RESPONSE = {"message": "Cloud Engineering API is running"}

app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/", summary="Landing page or service response", responses={200: {"content": {"text/html": {"schema": {"type": "string"}}}}})
def root(request: Request):
    accept = request.headers.get("accept", "")
    if "text/html" in accept and "application/json" not in accept:
        return FileResponse(STATIC_DIR / "index.html", media_type="text/html")
    return ROOT_RESPONSE


@app.get("/api", summary="Service response")
def api_root():
    return ROOT_RESPONSE


@app.get("/health", summary="Health check")
def health():
    return {"status": "healthy"}
