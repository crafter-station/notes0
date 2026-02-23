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
		INSERT INTO expenses (id, total, quantity, unit, description, created_at)
		VALUES ($1, $2, $3, $4, $5, $6)
	`

	_, err = db.ExecContext(ctx, query,
		expense.ID,
		expense.Total,
		expense.Quantity,
		expense.Unit,
		expense.Description,
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
		SELECT id, total, quantity, unit, description, created_at
		FROM expenses
		WHERE id = $1
	`

	var expense models.Expense
	err = db.QueryRowContext(ctx, query, id).Scan(
		&expense.ID,
		&expense.Total,
		&expense.Quantity,
		&expense.Unit,
		&expense.Description,
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
