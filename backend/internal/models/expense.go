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

// ListExpensesParams represents the parameters for listing expenses
type ListExpensesParams struct {
	Page    int
	PerPage int
	OrderBy string // "purchased_at" or "created_at"
	OrderDir string // "asc" or "desc"
}

// PaginatedExpenses represents a paginated response of expenses
type PaginatedExpenses struct {
	Data       []*Expense `json:"data"`
	Page       int        `json:"page"`
	PerPage    int        `json:"per_page"`
	Total      int        `json:"total"`
	TotalPages int        `json:"total_pages"`
}
