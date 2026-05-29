import asyncio
import os
import httpx
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="Core Bancario")

BACKOFFICE_URL = os.getenv("BACKOFFICE_URL", "http://localhost:3000")
MONTO_MAXIMO = 1_000_000


class TransferRequest(BaseModel):
    transfer_id: int
    amount: float
    idempotency_key: str


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/process_transfer")
async def process_transfer(request: TransferRequest):
    if request.amount > MONTO_MAXIMO:
        await notify_backoffice(request.transfer_id, "failed", request.idempotency_key)
        return {"status": "failed", "reason": "El monto supera el límite de $1.000.000 COP"}

    await asyncio.sleep(2)
    await notify_backoffice(request.transfer_id, "completed", request.idempotency_key)
    return {"status": "completed"}


async def notify_backoffice(transfer_id: int, status: str, idempotency_key: str):
    payload = {
        "transfer_id": transfer_id,
        "status": status,
        "idempotency_key": idempotency_key
    }
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            await client.post(f"{BACKOFFICE_URL}/webhooks/transfer_result", json=payload)
    except httpx.RequestError as e:
        print(f"Error notificando al backoffice: {e}")
