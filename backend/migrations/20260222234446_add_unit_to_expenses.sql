-- +goose Up
-- +goose StatementBegin
ALTER TABLE expenses ADD COLUMN unit VARCHAR(20) NOT NULL DEFAULT 'u';
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
ALTER TABLE expenses DROP COLUMN unit;
-- +goose StatementEnd
