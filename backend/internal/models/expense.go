package models

import "time"

// Expense represents an expense record
type Expense struct {
	ID          string    `json:"id"`
	Total       float64   `json:"total"`
	Quantity    float64   `json:"quantity"`
	Unit        string    `json:"unit"`
	Description string    `json:"description"`
	CreatedAt   time.Time `json:"created_at"`
}

// ExpenseData represents the data extracted from audio transcription
type ExpenseData struct {
	Total       float64 `json:"total"`
	Quantity    float64 `json:"quantity"`
	Unit        string  `json:"unit"`
	Description string  `json:"description"`
}
