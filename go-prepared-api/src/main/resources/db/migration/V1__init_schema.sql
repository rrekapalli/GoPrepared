-- Phase 1: core schema
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    google_id VARCHAR(128) UNIQUE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    profile_picture VARCHAR(512),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE journey_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(64) NOT NULL UNIQUE
);

CREATE TABLE journey_subtypes (
    id BIGSERIAL PRIMARY KEY,
    journey_type_id BIGINT NOT NULL REFERENCES journey_types(id),
    name VARCHAR(64) NOT NULL,
    UNIQUE (journey_type_id, name)
);

CREATE TABLE activities (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE locations (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(128) NOT NULL,
    country VARCHAR(128),
    type VARCHAR(64)
);

CREATE TABLE journeys (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    original_query TEXT NOT NULL,
    journey_type_id BIGINT REFERENCES journey_types(id),
    journey_subtype_id BIGINT REFERENCES journey_subtypes(id),
    activity_id BIGINT REFERENCES activities(id),
    location_id BIGINT REFERENCES locations(id),
    status VARCHAR(32) NOT NULL DEFAULT 'DRAFT',
    progress_percent INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cards (
    id BIGSERIAL PRIMARY KEY,
    journey_id BIGINT NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    summary TEXT NOT NULL,
    category VARCHAR(64) NOT NULL,
    icon VARCHAR(64) NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    viewed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE card_details (
    id BIGSERIAL PRIMARY KEY,
    card_id BIGINT NOT NULL UNIQUE REFERENCES cards(id) ON DELETE CASCADE,
    content JSONB NOT NULL
);

CREATE TABLE content_templates (
    id BIGSERIAL PRIMARY KEY,
    template_key VARCHAR(128) NOT NULL UNIQUE,
    journey_type VARCHAR(64),
    journey_subtype VARCHAR(64),
    activity VARCHAR(128),
    location VARCHAR(128),
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Phase 2
CREATE TABLE checklist_items (
    id BIGSERIAL PRIMARY KEY,
    journey_id BIGINT NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(64) NOT NULL,
    display_order INT NOT NULL DEFAULT 0,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    user_added BOOLEAN NOT NULL DEFAULT FALSE
);

-- Phase 3
CREATE TABLE knowledge_nodes (
    id BIGSERIAL PRIMARY KEY,
    node_type VARCHAR(32) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB,
    UNIQUE (node_type, name)
);

CREATE TABLE knowledge_edges (
    id BIGSERIAL PRIMARY KEY,
    source_node_id BIGINT NOT NULL REFERENCES knowledge_nodes(id),
    target_node_id BIGINT NOT NULL REFERENCES knowledge_nodes(id),
    relationship_type VARCHAR(32) NOT NULL
);

-- Phase 4
CREATE TABLE community_insights (
    id BIGSERIAL PRIMARY KEY,
    journey_id BIGINT REFERENCES journeys(id),
    user_id BIGINT REFERENCES users(id),
    insight_type VARCHAR(32) NOT NULL,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    votes INT NOT NULL DEFAULT 0,
    status VARCHAR(32) NOT NULL DEFAULT 'ACTIVE',
    severity VARCHAR(16),
    journey_context VARCHAR(128),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE community_insight_votes (
    id BIGSERIAL PRIMARY KEY,
    insight_id BIGINT NOT NULL REFERENCES community_insights(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id),
    helpful BOOLEAN NOT NULL,
    UNIQUE (insight_id, user_id)
);

-- Seed journey types
INSERT INTO journey_types (name) VALUES
('Travel'), ('Health'), ('Sports'), ('Education'), ('Career'), ('Government'), ('Events'), ('Finance'), ('Personal');

INSERT INTO journey_subtypes (journey_type_id, name)
SELECT jt.id, st.name FROM journey_types jt
JOIN (VALUES
    ('Travel', 'Vacation'), ('Travel', 'Business Travel'), ('Travel', 'Pilgrimage'),
    ('Health', 'Medical Procedure'), ('Health', 'Surgery'), ('Health', 'Diagnostic Test'),
    ('Sports', 'Marathon'), ('Sports', '10K Run'), ('Sports', 'Cycling')
) AS st(type_name, name) ON jt.name = st.type_name;
