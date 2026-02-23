package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
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
	expenses, err := h.service.ProcessAudioExpense(r.Context(), tmpFile.Name())
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to process expenses: %v", err), http.StatusInternalServerError)
		return
	}

	// Return success
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(expenses)
}
