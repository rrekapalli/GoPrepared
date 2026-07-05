-- OAuth provider identity columns (idempotent for partial prior applies)
ALTER TABLE users ADD COLUMN IF NOT EXISTS microsoft_id VARCHAR(128);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_microsoft_id ON users (microsoft_id) WHERE microsoft_id IS NOT NULL;
