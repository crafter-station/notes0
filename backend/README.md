# Expense Audio Processing API

Go API that processes expense audio recordings, extracts structured information using OpenAI (Whisper + GPT-4), and stores data in PostgreSQL.

✨ **Dual Mode:** Can run locally as HTTP server or deploy to AWS Lambda.

## Features

1. **Receives** audio file and optional `purchased_at` via multipart/form-data
2. **Transcribes** audio to text using OpenAI Whisper
3. **Extracts** structured data using OpenAI GPT-4:
   - `unit_price`: price per unit (float64)
   - `quantity`: quantity purchased (float64)
   - `unit`: unit of measurement (string: "kg", "litro", "pasaje", "u")
   - `description`: product description (string)
4. **Generates** unique ID (UUID) and timestamp
5. **Saves** to PostgreSQL (`expenses` table)
6. **Returns** created Expense object(s)

### Multiple Expenses Support

The API can detect and process **multiple expenses** from a single audio file.

**Example Audio:** "I bought 2kg of rice at $3.50 per kilo and 1 liter of oil at $4.20"

**Response:**
```json
[
  {
    "id": "uuid-1",
    "unit_price": 3.50,
    "quantity": 2.0,
    "unit": "kg",
    "description": "rice",
    "purchased_at": "2026-02-22T10:30:00Z",
    "created_at": "2026-02-22T18:00:00Z"
  },
  {
    "id": "uuid-2",
    "unit_price": 4.20,
    "quantity": 1.0,
    "unit": "litro",
    "description": "oil",
    "purchased_at": "2026-02-22T10:30:00Z",
    "created_at": "2026-02-22T18:00:01Z"
  }
]
```

## Prerequisites

1. **Go 1.21+** installed
2. **Make** installed
3. **Terraform** installed (for AWS deployment)
4. **AWS CLI** configured with credentials
5. **OpenAI API Key** ([get here](https://platform.openai.com/api-keys))
6. **PostgreSQL database** (local, RDS, Supabase, etc.)

## Quick Start

### 1. Install Dependencies

```bash
make install
```

This will install Go dependencies and goose migration tool.

### 2. Configure Environment

Copy the example file and add your credentials:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```env
OPENAI_API_KEY=sk-proj-your-key-here
DB_URL=postgres://user:password@localhost:5432/expenses?sslmode=disable
PORT=8080
```

⚠️ **DO NOT commit** the `.env` file (already in `.gitignore`)

### 3. Run Database Migrations

```bash
make migrate
```

This creates the `expenses` table and indexes.

### 4. Run the Server

```bash
make run
```

You should see:
```
🚀 Server starting on port 8080
📝 Test with: curl -X POST http://localhost:8080/upload -F "audio=@your-file.m4a"
```

### 5. Test Locally

```bash
# Basic request (purchased_at defaults to current time)
curl -X POST http://localhost:8080/upload \
  -F "audio=@test-expense.m4a"

# With custom purchased_at (RFC3339 format)
curl -X POST http://localhost:8080/upload \
  -F "audio=@test-expense.m4a" \
  -F "purchased_at=2026-02-22T10:30:00Z"
```

**Form Fields:**
- `audio` (required): Audio file (m4a, mp3, wav, etc.)
- `purchased_at` (optional): Purchase date/time in RFC3339 format (e.g., `2026-02-22T10:30:00Z`). Defaults to current time if not provided.

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make help` | Show all available commands |
| `make install` | Install dependencies and tools |
| `make run` | Run application locally |
| `make build` | Build binary for local testing |
| `make migrate` | Run all pending migrations |
| `make migrate-create NAME=xxx` | Create a new migration |
| `make migrate-down` | Rollback last migration |
| `make migrate-status` | Show migration status |
| `make deploy` | Build and deploy to AWS Lambda |
| `make deploy-plan` | Show Terraform deployment plan |
| `make destroy` | Destroy AWS Lambda resources |
| `make clean` | Clean build artifacts |
| `make test` | Run tests |
| `make fmt` | Format code |

## Database Migrations

This project uses **goose** for database migrations.

### Create a New Migration

```bash
make migrate-create NAME=add_user_field
```

This creates a new migration file in `migrations/`.

### Run Migrations

```bash
make migrate
```

### Rollback Last Migration

```bash
make migrate-down
```

### Check Migration Status

```bash
make migrate-status
```

## Architecture

### Clean Architecture with Layer Separation

```
Presentation → Business Logic → Data Access
  (handlers)      (services)      (repositories)
```

### Project Structure

```
backend/
├── main.go                          # Entry point, DI orchestration
├── Makefile                         # Build and deployment automation
├── go.mod                           # Go dependencies
├── .env.example                     # Environment template
├── internal/
│   ├── models/
│   │   └── expense.go              # Domain entities
│   ├── repositories/
│   │   ├── openai_repository.go    # OpenAI API interface
│   │   └── postgres_repository.go  # PostgreSQL interface
│   ├── services/
│   │   └── expense_service.go      # Business logic
│   └── handlers/
│       ├── router.go               # Chi router setup
│       ├── expense_handler.go      # HTTP handlers
│       └── lambda_handler.go       # Lambda adapter
├── migrations/
│   └── 00001_create_expenses_table.sql
└── terraform/
    ├── main.tf                      # AWS infrastructure
    ├── variables.tf                 # Terraform variables
    └── outputs.tf                   # Outputs (API URL)
```

## Deployment to AWS Lambda

### 1. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
openai_api_key = "sk-proj-..."
db_url = "postgres://user:password@host:5432/database?sslmode=require"
```

### 2. Deploy

```bash
make deploy
```

Terraform will:
- Build the Lambda binary
- Create the ZIP file
- Deploy to AWS Lambda
- Configure API Gateway

### 3. Test Production

```bash
curl -X POST https://<api-url>/upload \
  -F "audio=@test-expense.m4a"
```

### 4. Destroy Resources

```bash
make destroy
```

## How Dual Mode Works

The code automatically detects the environment:

**🖥️ Local Mode (development):**
- Runs with `make run`
- Loads variables from `.env`
- Starts HTTP server on port 8080
- Logs visible in console

**☁️ Lambda Mode (production):**
- Detects `AWS_LAMBDA_FUNCTION_NAME` variable
- Uses Lambda environment variables
- Handles API Gateway events
- Logs to CloudWatch

## Lambda Configuration

- **Runtime:** provided.al2023 (Go custom runtime)
- **Timeout:** 90 seconds
- **Memory:** 512 MB
- **Handler:** bootstrap

## Dependencies

- `github.com/aws/aws-lambda-go` - Lambda runtime
- `github.com/go-chi/chi/v5` - HTTP router
- `github.com/google/uuid` - UUID generation
- `github.com/joho/godotenv` - .env file loader
- `github.com/lib/pq` - PostgreSQL driver
- `github.com/pressly/goose/v3` - Database migrations
- `github.com/sashabaranov/go-openai` - OpenAI API client

## Supported Audio Formats

OpenAI Whisper supports:
- mp3
- mp4
- m4a
- wav
- webm

Maximum file size: 25 MB

## Estimated Costs

- **OpenAI Whisper:** ~$0.006 per minute of audio
- **OpenAI GPT-4:** ~$0.01 per request
- **AWS Lambda:** Based on duration (~60s per request)
- **PostgreSQL:** Depends on provider (RDS, Supabase, etc.)

## Troubleshooting

### Error: "OPENAI_API_KEY not configured"
Verify you've set the variable in `.env` and run `make migrate`.

### Error: "Failed to connect to database"
- Check that the connection string is correct
- Ensure the database is accessible from your environment
- For remote databases, use `sslmode=require`

### Error: "prepared statement name is already in use" (Neon Database)
This occurs when using Neon's **connection pooler** endpoint for migrations.

**Solution:** Use Neon's **direct connection** endpoint for migrations:
```env
# ❌ Don't use pooler for migrations
DB_URL=postgresql://user:pass@ep-xxx-pooler.us-east-1.aws.neon.tech/db

# ✅ Use direct endpoint instead (remove -pooler)
DB_URL=postgresql://user:pass@ep-xxx.us-east-1.aws.neon.tech/db
```

The pooler uses PgBouncer in transaction mode, which doesn't support prepared statements that goose requires. Find your direct connection string in the Neon dashboard under "Connection Details" → "Direct connection".

### Lambda timeout
If processing very long audio files, increase timeout in `terraform/main.tf`:

```hcl
timeout = 120  # 2 minutes
```

## Development

### Format Code

```bash
make fmt
```

### Run Tests

```bash
make test
```

### Run Linter

```bash
make lint
```

## License

MIT
