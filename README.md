# test-transfer-hub

Monorepo con dos servicios que se comunican de forma asíncrona e idempotente para procesar transferencias financieras.

- **backoffice** — API REST en Ruby on Rails + Sidekiq
- **core-bancario** — Servicio de procesamiento en Python (FastAPI)

---

## Arquitectura

```
Cliente
  │
  ▼
[Rails Backoffice :3000]
  │  POST /transfers
  │  → guarda Transfer (pending)
  │  → encola TransferJob en Sidekiq
  │
  ▼
[Sidekiq Worker]
  │  → cambia estado a processing
  │  → llama POST /process_transfer
  │
  ▼
[Python FastAPI :8000]
  │  → valida monto ≤ $1.000.000 COP
  │  → simula procesamiento (sleep 2s)
  │  → llama POST /webhooks/transfer_result
  │
  ▼
[Rails Backoffice :3000]
  │  → actualiza estado: completed / failed
  │  → idempotente: si llega dos veces, ignora la segunda
```

### Estados de una transferencia

```
pending → processing → completed
                    ↘ failed
```

---

## Requisitos

- Docker
- Docker Compose

---

## Levantar el proyecto

```bash
git clone https://github.com/NiGiInRo/test-transfer-hub.git
cd test-transfer-hub
docker compose up
```

Esto levanta automáticamente:

| Servicio        | Puerto | Descripción                  |
|-----------------|--------|------------------------------|
| Rails           | 3000   | API REST backoffice          |
| Sidekiq         | —      | Procesador de jobs           |
| Python FastAPI  | 8000   | Core bancario                |
| PostgreSQL      | 5432   | Base de datos                |
| Redis           | 6379   | Cola de Sidekiq              |

### Dashboard Sidekiq

```
http://localhost:3000/sidekiq
```

---

## Endpoints

### POST /transfers

Crea una transferencia. Si el `idempotency_key` ya existe, retorna la transferencia existente sin crear un duplicado.

```bash
curl -X POST http://localhost:3000/transfers \
  -H "Content-Type: application/json" \
  -d '{"transfer": {"user_id": 1, "amount": 50000, "idempotency_key": "key-001"}}'
```

**Respuesta exitosa (201):**
```json
{
  "id": 1,
  "user_id": 1,
  "amount": "50000.0",
  "idempotency_key": "key-001",
  "status": "pending",
  "created_at": "2026-05-29T15:00:00.000Z",
  "updated_at": "2026-05-29T15:00:00.000Z"
}
```

**Respuesta idempotente (200):** misma transferencia si el `idempotency_key` ya existe.

---

### GET /transfers/:id

Consulta el estado actual de una transferencia.

```bash
curl http://localhost:3000/transfers/1
```

**Respuesta (200):**
```json
{
  "id": 1,
  "user_id": 1,
  "amount": "50000.0",
  "idempotency_key": "key-001",
  "status": "completed",
  "created_at": "2026-05-29T15:00:00.000Z",
  "updated_at": "2026-05-29T15:00:02.000Z"
}
```

---

### POST /webhooks/transfer_result

Recibe el resultado del core bancario y actualiza el estado de la transferencia. Es completamente idempotente — si el webhook llega dos veces, el estado no cambia.

```bash
curl -X POST http://localhost:3000/webhooks/transfer_result \
  -H "Content-Type: application/json" \
  -d '{"transfer_id": 1, "status": "completed", "idempotency_key": "key-001"}'
```

---

### POST /process_transfer (core bancario)

```bash
curl -X POST http://localhost:8000/process_transfer \
  -H "Content-Type: application/json" \
  -d '{"transfer_id": 1, "amount": 50000, "idempotency_key": "key-001"}'
```

**Regla de negocio:** si `amount > 1.000.000 COP`, la transferencia es rechazada.

```bash
curl -X POST http://localhost:8000/process_transfer \
  -H "Content-Type: application/json" \
  -d '{"transfer_id": 2, "amount": 1500000, "idempotency_key": "key-002"}'
```

```json
{
  "status": "failed",
  "reason": "El monto supera el límite de $1.000.000 COP"
}
```

---

## Correr los tests

```bash
docker exec -it transfer-hub-rails bundle exec rspec
```

---

## Tasks implementadas

| Task | Descripción |
|------|-------------|
| Task 01 | Setup del entorno con Docker — monorepo con todos los servicios orquestados via Docker Compose |
| Task 02 | Modelo y migraciones — tabla `transfers` con estados enum e índice único en `idempotency_key` |
| Task 03 | Endpoint `POST /transfers` con idempotencia real basada en `idempotency_key` |
| Task 04 | Endpoint `GET /transfers/:id` para consultar el estado de una transferencia |
| Task 05 | Sidekiq Job — procesamiento asíncrono con máximo 3 reintentos y estado `failed` al agotar reintentos |
| Task 06 | Core bancario en Python — valida monto, simula procesamiento y notifica al backoffice vía webhook |
| Task 07 | Webhook idempotente — actualiza estado solo si la transferencia está en `processing`, ignora llamadas duplicadas |
| Task 08 | Tests con RSpec — cobertura de idempotencia del webhook y comportamiento del endpoint de transferencias |
