# Life Control API Documentation (MVP)

Документация для мобильного backend API (Laravel 12, PHP 8.2).

## 1) Base URL и общие правила

- Base URL (local): `http://127.0.0.1:8000/api`
- Формат: JSON
- Аутентификация: Bearer token (Laravel Sanctum)
- Все protected endpoints требуют header:
  - `Authorization: Bearer <token>`
  - `Accept: application/json`

## 2) Глобальные настройки домена

- Default currency: `KZT`
- Default timezone: `Asia/Qyzylorda`
- Supported languages: `ru`, `en`
- Поддерживаемые intents:
  - `create_expense`
  - `create_income`
  - `create_task`
  - `create_tasks`
  - `finance_analysis`
  - `task_query`
  - `unknown`

## 3) Auth API

### POST `/register`
Создаёт пользователя и возвращает токен.

Request:
```json
{
  "name": "Test",
  "email": "test@example.com",
  "password": "password123",
  "locale": "ru",
  "timezone": "Asia/Qyzylorda",
  "default_currency": "KZT"
}
```

Response `201`:
```json
{
  "token": "1|sanctum_token_here",
  "user": {
    "id": 1,
    "name": "Test",
    "email": "test@example.com",
    "locale": "ru",
    "timezone": "Asia/Qyzylorda",
    "default_currency": "KZT"
  }
}
```

### POST `/login`

Request:
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```

Response `200`:
```json
{
  "token": "2|sanctum_token_here",
  "user": {
    "id": 1,
    "name": "Test",
    "email": "test@example.com"
  }
}
```

Ошибка `422`:
```json
{
  "message": "Invalid credentials"
}
```

### POST `/logout`
Удаляет текущий access token.

Response `200`:
```json
{
  "message": "Logged out"
}
```

## 4) AI API

## POST `/ai/parse-text`
Парсит текст, определяет intent, создаёт запись (transaction/task) и логирует interaction.

Request:
```json
{
  "text": "Я потратил в магазине 7000 на рыбу и сигареты"
}
```

Response `200` (resource-обёртка):
```json
{
  "data": {
    "parsed": {
      "intent": "create_expense",
      "language": "ru",
      "confidence": 0.92,
      "expense": {
        "amount": 7000,
        "currency": "KZT",
        "category": "other",
        "date": "2026-04-21"
      },
      "tasks": []
    },
    "transaction": {
      "id": 10,
      "type": "expense",
      "amount": 7000,
      "currency": "KZT",
      "transaction_date": "2026-04-21",
      "needs_confirmation": true,
      "category": "other",
      "items": []
    },
    "tasks": [],
    "interaction_id": 3
  }
}
```

## POST `/ai/parse-voice`
- Принимает файл `audio` (`mp3,wav,m4a,ogg`, max `20MB`)
- Сохраняет файл
- MVP статус: транскрипция пока заглушка (`Voice transcription is not implemented yet`)

Form-data:
- `audio`: file

Response: формат как у `/ai/parse-text`

## POST `/ai/parse-receipt`
- Принимает файл `image` (`jpg,jpeg,png,webp`, max `10MB`)
- Сохраняет файл
- MVP статус: vision-parsing пока заглушка (`Analyze uploaded receipt`)

Form-data:
- `image`: file

Response: формат как у `/ai/parse-text`

## 5) Transactions API

### GET `/transactions`
Пагинированный список текущего пользователя.

Response `200`:
```json
{
  "data": [
    {
      "id": 1,
      "type": "expense",
      "amount": 1000,
      "currency": "KZT",
      "transaction_date": "2026-04-21",
      "merchant": "магазин",
      "source": null,
      "description": "рыба",
      "raw_text": null,
      "needs_confirmation": false,
      "category": "food",
      "items": []
    }
  ],
  "links": {},
  "meta": {}
}
```

### POST `/transactions`

Request:
```json
{
  "type": "expense",
  "amount": 2500,
  "currency": "KZT",
  "date": "2026-04-21",
  "category": "food",
  "merchant": "магазин",
  "description": "продукты",
  "items": [
    {
      "name": "яблоки",
      "quantity": 2,
      "unit": "kg",
      "price": 1200
    }
  ]
}
```

Response `200`: `TransactionResource`

### GET `/transactions/{transaction}`
Возвращает конкретную транзакцию (owner-only policy).

### PATCH `/transactions/{transaction}`
Частичное обновление полей:
- `amount`, `currency`, `date`, `merchant`, `source`, `description`

### DELETE `/transactions/{transaction}`
Response `204 No Content`

### POST `/transactions/{transaction}/confirm`
Снимает `needs_confirmation`, проставляет `confirmed_at`.

Response `200`: `TransactionResource`

## 6) Finance Summary API

### GET `/finance/summary/weekly`
### GET `/finance/summary/monthly`

Оба endpoint’а считают итоги из БД (не из LLM).

Response `200`:
```json
{
  "period_start": "2026-04-20",
  "period_end": "2026-04-26",
  "income_total": 30000,
  "expense_total": 7000,
  "balance": 23000,
  "expenses_by_category": [
    {
      "category": "food",
      "total": 4000
    },
    {
      "category": "tobacco",
      "total": 3000
    }
  ]
}
```

## 7) Tasks API

### GET `/tasks`
Пагинированный список задач текущего пользователя.

### POST `/tasks`

Request:
```json
{
  "title": "Позвонить клиенту",
  "description": "вечером",
  "category": "work",
  "priority": "normal",
  "status": "pending",
  "due_date": "2026-04-22",
  "due_time": null
}
```

Response `200`:
```json
{
  "data": {
    "id": 1,
    "title": "Позвонить клиенту",
    "description": "вечером",
    "raw_text": null,
    "status": "pending",
    "priority": "normal",
    "due_date": "2026-04-22",
    "due_time": null,
    "needs_confirmation": false,
    "category": "work"
  }
}
```

### GET `/tasks/{task}`
### PATCH `/tasks/{task}`
Обновляемые поля:
- `title`, `description`, `priority`, `status`, `due_date`, `due_time`

### DELETE `/tasks/{task}`
Response `204 No Content`

### POST `/tasks/{task}/complete`
Ставит статус `completed`.

### POST `/tasks/{task}/cancel`
Ставит статус `cancelled`.

## 8) Categories API

### GET `/categories`
Возвращает системные + пользовательские категории.

### POST `/categories`

Request:
```json
{
  "type": "expense",
  "slug": "pets",
  "name_ru": "Питомцы",
  "name_en": "Pets"
}
```

### PATCH `/categories/{category}`
Обновляет только:
- `name_ru`
- `name_en`

### DELETE `/categories/{category}`
Удаляет только пользовательские категории (system удалять нельзя).

## 9) Валидация и бизнес-ограничения (MVP)

- Transaction type: `income|expense`
- Task status: `pending|completed|cancelled`
- Task priority: `low|normal|high`
- AI income/expense создаются с `needs_confirmation=true`
- `raw_text` сохраняется в оригинале
- Не нужно переводить пользовательские title/description/note
- Внутренние category slug должны быть на английском

## 10) Стандартные ошибки

### 401 Unauthorized
Нет токена или невалидный токен.

### 403 Forbidden
Нет прав на ресурс (policy).

### 404 Not Found
Ресурс не найден.

### 422 Unprocessable Entity
Ошибка валидации.

Пример:
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "amount": [
      "The amount field is required."
    ]
  }
}
```

## 11) Быстрые cURL примеры

Register:
```bash
curl -X POST http://127.0.0.1:8000/api/register \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{\"name\":\"Test\",\"email\":\"test@example.com\",\"password\":\"password123\"}"
```

Parse text:
```bash
curl -X POST http://127.0.0.1:8000/api/ai/parse-text \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <token>" \
  -d "{\"text\":\"I spent 7000 at the store\"}"
```

Weekly summary:
```bash
curl -X GET http://127.0.0.1:8000/api/finance/summary/weekly \
  -H "Accept: application/json" \
  -H "Authorization: Bearer <token>"
```

---

Если нужно, могу следующим шагом сделать вторую версию в формате OpenAPI 3.1 (`openapi.yaml`), чтобы Cursor/Claude могли использовать её как machine-readable контракт.
