package handlers

import (
	"net/http"
	"upload-lambda/internal/services"

	_ "upload-lambda/docs" // Import swagger docs

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	httpSwagger "github.com/swaggo/http-swagger"
)

// NewRouter creates and configures the HTTP router
func NewRouter(service services.ExpenseService) http.Handler {
	r := chi.NewRouter()

	// Middleware
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.RealIP)

	// Create expense handler
	expenseHandler := NewExpenseHandler(service)

	// Routes
	r.Post("/upload", expenseHandler.HandleUpload)
	r.Get("/expenses", expenseHandler.HandleList)

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Swagger documentation
	r.Get("/swagger/*", httpSwagger.WrapHandler)

	return r
}
