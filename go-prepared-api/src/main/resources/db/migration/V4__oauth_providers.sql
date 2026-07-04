-- OAuth provider identity columns
ALTER TABLE users ADD COLUMN microsoft_id VARCHAR(128);

CREATE UNIQUE INDEX idx_users_microsoft_id ON users (microsoft_id) WHERE microsoft_id IS NOT NULL;
