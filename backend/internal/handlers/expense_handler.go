package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"time"
	"upload-lambda/internal/models"
	"upload-lambda/internal/services"
)

// ExpenseHandler handles HTTP requests for expenses
type ExpenseHandler struct {
	service services.ExpenseService
}

// NewExpenseHandler creates a new expense handler
func NewExpenseHandler(service services.ExpenseService) *ExpenseHandler {
	return &ExpenseHandler{
		service: service,
	}
}

// HandleUpload handles the upload of audio files
func (h *ExpenseHandler) HandleUpload(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse multipart form (32 MB max)
	err := r.ParseMultipartForm(32 << 20)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to parse form: %v", err), http.StatusBadRequest)
		return
	}

	// Get purchased_at from form (optional, defaults to now)
	purchasedAtStr := r.FormValue("purchased_at")
	var purchasedAt time.Time
	if purchasedAtStr != "" {
		purchasedAt, err = time.Parse(time.RFC3339, purchasedAtStr)
		if err != nil {
			http.Error(w, fmt.Sprintf("Invalid purchased_at format (expected RFC3339): %v", err), http.StatusBadRequest)
			return
		}
	} else {
		purchasedAt = time.Now().UTC()
	}

	// Get audio file
	file, header, err := r.FormFile("audio")
	if err != nil {
		http.Error(w, "No audio file provided", http.StatusBadRequest)
		return
	}
	defer file.Close()

	// Save to temp file
	tmpFile, err := os.CreateTemp("", "audio-*"+filepath.Ext(header.Filename))
	if err != nil {
		http.Error(w, "Failed to create temp file", http.StatusInternalServerError)
		return
	}
	defer os.Remove(tmpFile.Name())
	defer tmpFile.Close()

	_, err = io.Copy(tmpFile, file)
	if err != nil {
		http.Error(w, "Failed to save file", http.StatusInternalServerError)
		return
	}

	// Process expenses (may be multiple)
	expenses, err := h.service.ProcessAudioExpense(r.Context(), tmpFile.Name(), purchasedAt)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to process expenses: %v", err), http.StatusInternalServerError)
		return
	}

	// Return success
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(expenses)
}

// HandleList handles the listing of expenses with pagination
func (h *ExpenseHandler) HandleList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	// Parse query parameters
	query := r.URL.Query()

	// Get page (default: 1)
	page := 1
	if pageStr := query.Get("page"); pageStr != "" {
		fmt.Sscanf(pageStr, "%d", &page)
	}

	// Get per_page (default: 10, max: 100)
	perPage := 10
	if perPageStr := query.Get("per_page"); perPageStr != "" {
		fmt.Sscanf(perPageStr, "%d", &perPage)
	}

	// Get order[by] (default: created_at)
	orderBy := query.Get("order[by]")
	if orderBy == "" {
		orderBy = "created_at"
	}

	// Get order[dir] (default: desc)
	orderDir := query.Get("order[dir]")
	if orderDir == "" {
		orderDir = "desc"
	}

	// Create params
	params := models.ListExpensesParams{
		Page:     page,
		PerPage:  perPage,
		OrderBy:  orderBy,
		OrderDir: orderDir,
	}

	// Call service
	result, err := h.service.ListExpenses(r.Context(), params)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to list expenses: %v", err), http.StatusInternalServerError)
		return
	}

	// Return success
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(result)
}
