from fastapi import FastAPI

app = FastAPI(title="Core Bancario")

@app.get("/health")
def health():
    return {"status": "ok"}
