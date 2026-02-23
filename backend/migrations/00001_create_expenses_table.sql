-- +goose Up
-- +goose StatementBegin
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY,
    total DECIMAL(10, 2) NOT NULL,
    quantity DECIMAL(10, 2) NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Create index on created_at for faster queries
CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses(created_at DESC);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP INDEX IF EXISTS idx_expenses_created_at;
DROP TABLE IF EXISTS expenses;
-- +goose StatementEnd
