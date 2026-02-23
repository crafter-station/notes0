package models

import "time"

// Expense represents an expense record
type Expense struct {
	ID          string    `json:"id"`
	UnitPrice   float64   `json:"unit_price"`
	Quantity    float64   `json:"quantity"`
	Unit        string    `json:"unit"`
	Description string    `json:"description"`
	PurchasedAt time.Time `json:"purchased_at"`
	CreatedAt   time.Time `json:"created_at"`
}

// ExpenseData represents the data extracted from audio transcription
type ExpenseData struct {
	UnitPrice   float64 `json:"unit_price"`
	Quantity    float64 `json:"quantity"`
	Unit        string  `json:"unit"`
	Description string  `json:"description"`
}
