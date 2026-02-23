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
// @Summary Upload audio and extract expenses
// @Description Uploads an audio file, transcribes it using OpenAI Whisper, and extracts expense data using GPT-4
// @Tags expenses
// @Accept multipart/form-data
// @Produce json
// @Param audio formData file true "Audio file (m4a, mp3, wav, etc.)"
// @Param purchased_at formData string false "Purchase date/time in RFC3339 format (e.g., 2026-02-22T10:30:00Z)"
// @Success 200 {array} models.Expense "List of extracted expenses"
// @Failure 400 {object} map[string]string "Bad request"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /upload [post]
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
// @Summary List expenses with pagination
// @Description Retrieves a paginated list of expenses with optional sorting
// @Tags expenses
// @Produce json
// @Param page query int false "Page number (default: 1)"
// @Param per_page query int false "Items per page (default: 10, max: 100)"
// @Param order[by] query string false "Sort field: purchased_at or created_at (default: created_at)"
// @Param order[dir] query string false "Sort direction: asc or desc (default: desc)"
// @Success 200 {object} models.PaginatedExpenses "Paginated list of expenses"
// @Failure 500 {object} map[string]string "Internal server error"
// @Router /expenses [get]
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
