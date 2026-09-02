from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def root():
    return {"message": "Cloud Engineering API is running"}


@app.get("/health")
def health():
    return {"status": "healthy"}