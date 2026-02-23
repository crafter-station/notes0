package main

import (
	"log"
	"net/http"
	"os"
	"upload-lambda/internal/handlers"
	"upload-lambda/internal/repositories"
	"upload-lambda/internal/services"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/joho/godotenv"
)

func main() {
	// Load environment variables from .env file (local development only)
	if os.Getenv("AWS_LAMBDA_FUNCTION_NAME") == "" {
		if err := godotenv.Load(); err != nil {
			log.Println("No .env file found, using system environment variables")
		}
	}

	// Get configuration from environment
	openaiAPIKey := os.Getenv("OPENAI_API_KEY")
	dbURL := os.Getenv("DB_URL")
	port := os.Getenv("PORT")

	if openaiAPIKey == "" {
		log.Fatal("OPENAI_API_KEY environment variable is required")
	}
	if dbURL == "" {
		log.Fatal("DB_URL environment variable is required")
	}
	if port == "" {
		port = "8080"
	}

	// Initialize repositories
	openaiRepo := repositories.NewOpenAIRepository(openaiAPIKey)
	expenseRepo := repositories.NewPostgresRepository(dbURL)

	// Create service with dependency injection
	expenseService := services.NewExpenseService(openaiRepo, expenseRepo)

	// Route based on environment
	if os.Getenv("AWS_LAMBDA_FUNCTION_NAME") != "" {
		// Lambda mode
		lambdaHandler := handlers.NewLambdaHandler(expenseService)
		lambda.Start(lambdaHandler.Handle)
	} else {
		// HTTP server mode (local development)
		router := handlers.NewRouter(expenseService)

		log.Printf("🚀 Server starting on port %s", port)
		log.Printf("📝 Test with: curl -X POST http://localhost:%s/upload -F \"audio=@your-file.m4a\"", port)

		if err := http.ListenAndServe(":"+port, router); err != nil {
			log.Fatal(err)
		}
	}
}
