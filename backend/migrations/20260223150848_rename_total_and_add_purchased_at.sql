-- +goose Up
-- +goose StatementBegin
ALTER TABLE expenses RENAME COLUMN total TO unit_price;
ALTER TABLE expenses ADD COLUMN purchased_at TIMESTAMP NOT NULL DEFAULT NOW();
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE expenses DROP COLUMN purchased_at;
ALTER TABLE expenses RENAME COLUMN unit_price TO total;
-- +goose StatementEnd
