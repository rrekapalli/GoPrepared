CREATE EXTENSION IF NOT EXISTS vector;

-- Static content tables (populated by import-content script)
CREATE TABLE IF NOT EXISTS content_templates (
    id BIGSERIAL PRIMARY KEY,
    template_key VARCHAR(128) NOT NULL UNIQUE,
    journey_type VARCHAR(64),
    journey_subtype VARCHAR(64),
    activity VARCHAR(128),
    location VARCHAR(128),
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_templates_type ON content_templates(journey_type, journey_subtype);
