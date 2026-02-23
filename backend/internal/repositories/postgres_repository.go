package repositories

import (
	"context"
	"database/sql"
	"fmt"
	"upload-lambda/internal/models"

	_ "github.com/lib/pq"
)

// ExpenseRepository defines the interface for expense data operations
type ExpenseRepository interface {
	Create(ctx context.Context, expense *models.Expense) error
	FindByID(ctx context.Context, id string) (*models.Expense, error)
	List(ctx context.Context, params models.ListExpensesParams) (*models.PaginatedExpenses, error)
}

type postgresRepo struct {
	dbURL string
}

// NewPostgresRepository creates a new PostgreSQL repository
func NewPostgresRepository(dbURL string) ExpenseRepository {
	return &postgresRepo{
		dbURL: dbURL,
	}
}

func (r *postgresRepo) Create(ctx context.Context, expense *models.Expense) error {
	db, err := sql.Open("postgres", r.dbURL)
	if err != nil {
		return fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()

	if err := db.PingContext(ctx); err != nil {
		return fmt.Errorf("failed to ping database: %w", err)
	}

	query := `
		INSERT INTO expenses (id, unit_price, quantity, unit, description, purchased_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`

	_, err = db.ExecContext(ctx, query,
		expense.ID,
		expense.UnitPrice,
		expense.Quantity,
		expense.Unit,
		expense.Description,
		expense.PurchasedAt,
		expense.CreatedAt,
	)

	if err != nil {
		return fmt.Errorf("failed to insert expense: %w", err)
	}

	return nil
}

func (r *postgresRepo) FindByID(ctx context.Context, id string) (*models.Expense, error) {
	db, err := sql.Open("postgres", r.dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	query := `
		SELECT id, unit_price, quantity, unit, description, purchased_at, created_at
		FROM expenses
		WHERE id = $1
	`

	var expense models.Expense
	err = db.QueryRowContext(ctx, query, id).Scan(
		&expense.ID,
		&expense.UnitPrice,
		&expense.Quantity,
		&expense.Unit,
		&expense.Description,
		&expense.PurchasedAt,
		&expense.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, fmt.Errorf("expense not found")
	}
	if err != nil {
		return nil, fmt.Errorf("failed to query expense: %w", err)
	}

	return &expense, nil
}

func (r *postgresRepo) List(ctx context.Context, params models.ListExpensesParams) (*models.PaginatedExpenses, error) {
	db, err := sql.Open("postgres", r.dbURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	defer db.Close()

	if err := db.PingContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	// Validate and set defaults
	if params.Page < 1 {
		params.Page = 1
	}
	if params.PerPage < 1 || params.PerPage > 100 {
		params.PerPage = 10
	}
	if params.OrderBy != "purchased_at" && params.OrderBy != "created_at" {
		params.OrderBy = "created_at"
	}
	if params.OrderDir != "asc" && params.OrderDir != "desc" {
		params.OrderDir = "desc"
	}

	// Count total records
	var total int
	countQuery := `SELECT COUNT(*) FROM expenses`
	err = db.QueryRowContext(ctx, countQuery).Scan(&total)
	if err != nil {
		return nil, fmt.Errorf("failed to count expenses: %w", err)
	}

	// Calculate offset
	offset := (params.Page - 1) * params.PerPage

	// Build query with ORDER BY
	query := fmt.Sprintf(`
		SELECT id, unit_price, quantity, unit, description, purchased_at, created_at
		FROM expenses
		ORDER BY %s %s
		LIMIT $1 OFFSET $2
	`, params.OrderBy, params.OrderDir)

	rows, err := db.QueryContext(ctx, query, params.PerPage, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to query expenses: %w", err)
	}
	defer rows.Close()

	var expenses []*models.Expense
	for rows.Next() {
		var expense models.Expense
		err := rows.Scan(
			&expense.ID,
			&expense.UnitPrice,
			&expense.Quantity,
			&expense.Unit,
			&expense.Description,
			&expense.PurchasedAt,
			&expense.CreatedAt,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to scan expense: %w", err)
		}
		expenses = append(expenses, &expense)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating expenses: %w", err)
	}

	// Calculate total pages
	totalPages := (total + params.PerPage - 1) / params.PerPage

	return &models.PaginatedExpenses{
		Data:       expenses,
		Page:       params.Page,
		PerPage:    params.PerPage,
		Total:      total,
		TotalPages: totalPages,
	}, nil
}
