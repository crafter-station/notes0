.PHONY: help install run build deploy destroy migrate migrate-create migrate-down migrate-status clean test

# Variables
APP_NAME=expense-audio-api
BINARY_NAME=bootstrap
MIGRATIONS_DIR=./migrations

# Load .env file if it exists
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies and tools
	@echo "📦 Installing Go dependencies..."
	go mod download
	go mod tidy
	@echo "🔧 Installing goose..."
	go install github.com/pressly/goose/v3/cmd/goose@latest
	@echo "🔧 Installing swag..."
	go install github.com/swaggo/swag/cmd/swag@latest
	@echo "✅ Installation complete"

run: ## Run the application locally
	@echo "🚀 Starting server..."
	go run main.go

build: ## Build the application for local testing
	@echo "🔨 Building application..."
	go build -o $(APP_NAME) .
	@echo "✅ Build complete: ./$(APP_NAME)"

build-lambda: ## Build Lambda binary for deployment
	@echo "🔨 Building Lambda binary..."
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -tags lambda.norpc -o $(BINARY_NAME) main.go
	@echo "✅ Lambda binary built: ./$(BINARY_NAME)"

migrate: ## Run all pending migrations
	@echo "🔄 Running database migrations..."
	@if [ -z "$(DB_URL)" ]; then \
		echo "❌ Error: DB_URL not set. Please set it in .env or environment"; \
		exit 1; \
	fi
	goose -dir $(MIGRATIONS_DIR) postgres "$(DB_URL)" up
	@echo "✅ Migrations complete"

migrate-down: ## Rollback the last migration
	@echo "⬇️  Rolling back last migration..."
	@if [ -z "$(DB_URL)" ]; then \
		echo "❌ Error: DB_URL not set. Please set it in .env or environment"; \
		exit 1; \
	fi
	goose -dir $(MIGRATIONS_DIR) postgres "$(DB_URL)" down
	@echo "✅ Rollback complete"

migrate-status: ## Show migration status
	@echo "📊 Migration status:"
	@if [ -z "$(DB_URL)" ]; then \
		echo "❌ Error: DB_URL not set. Please set it in .env or environment"; \
		exit 1; \
	fi
	goose -dir $(MIGRATIONS_DIR) postgres "$(DB_URL)" status

migrate-create: ## Create a new migration (usage: make migrate-create NAME=migration_name)
	@if [ -z "$(NAME)" ]; then \
		echo "❌ Error: NAME not provided. Usage: make migrate-create NAME=migration_name"; \
		exit 1; \
	fi
	@echo "📝 Creating new migration: $(NAME)"
	goose -dir $(MIGRATIONS_DIR) create $(NAME) sql
	@echo "✅ Migration created in $(MIGRATIONS_DIR)/"

deploy: build-lambda ## Deploy to AWS Lambda via Terraform
	@echo "☁️  Deploying to AWS Lambda..."
	cd terraform && terraform init && terraform apply -auto-approve
	@echo "✅ Deployment complete"

deploy-plan: ## Show Terraform deployment plan
	@echo "📋 Showing deployment plan..."
	cd terraform && terraform init && terraform plan

destroy: ## Destroy AWS Lambda deployment
	@echo "🗑️  Destroying AWS Lambda deployment..."
	@read -p "Are you sure you want to destroy? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd terraform && terraform destroy -auto-approve; \
		echo "✅ Resources destroyed"; \
	else \
		echo "❌ Destroy cancelled"; \
	fi

clean: ## Clean build artifacts
	@echo "🧹 Cleaning build artifacts..."
	rm -f $(APP_NAME) $(BINARY_NAME) lambda.zip
	rm -rf terraform/.terraform terraform/terraform.tfstate*
	@echo "✅ Clean complete"

test: ## Run tests
	@echo "🧪 Running tests..."
	go test -v ./...

fmt: ## Format code
	@echo "🎨 Formatting code..."
	go fmt ./...
	@echo "✅ Format complete"

swagger: ## Generate Swagger documentation
	@echo "📚 Generating Swagger documentation..."
	@if ! command -v swag &> /dev/null; then \
		echo "⚠️  swag not installed. Installing..."; \
		go install github.com/swaggo/swag/cmd/swag@latest; \
	fi
	swag init
	@echo "✅ Swagger documentation generated in ./docs"

lint: ## Run linter
	@echo "🔍 Running linter..."
	@if ! command -v golangci-lint &> /dev/null; then \
		echo "⚠️  golangci-lint not installed. Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	else \
		golangci-lint run; \
	fi

dev: ## Run in development mode with live reload (requires air)
	@echo "🔄 Starting development server..."
	@if ! command -v air &> /dev/null; then \
		echo "⚠️  air not installed. Installing..."; \
		go install github.com/cosmtrek/air@latest; \
	fi
	air

logs: ## Show Lambda logs (requires AWS CLI)
	@echo "📜 Fetching Lambda logs..."
	aws logs tail /aws/lambda/upload-audio --follow

# Docker targets
docker-build: ## Build Docker image
	@echo "🐳 Building Docker image..."
	docker build -t $(APP_NAME):latest .

docker-run: ## Run Docker container
	@echo "🐳 Running Docker container..."
	docker run -p 8080:8080 --env-file .env $(APP_NAME):latest
