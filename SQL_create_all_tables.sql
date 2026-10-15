-- ============================================================================
-- Auto Electro Dynamics — Facial Recognition System
-- Complete table provisioning script  (PostgreSQL, shared DB server)
--
-- All tables are namespaced with the suffix  _auto_electro_dynamics  so this
-- client's data lives alongside other clients on the same Postgres server
-- without collision. Safe to re-run (IF NOT EXISTS / ON CONFLICT).
--
-- The web app also auto-creates these via SQLAlchemy db.create_all() on first
-- start; this script is provided for explicit/standalone provisioning.
-- ============================================================================

-- ============================================================
-- Users
-- ============================================================
CREATE TABLE IF NOT EXISTS users_facial_recognition_auto_electro_dynamics (
    id            SERIAL PRIMARY KEY,
    user_id       VARCHAR(36)  NOT NULL UNIQUE DEFAULT gen_random_uuid()::TEXT,
    username      VARCHAR(80)  NOT NULL UNIQUE,
    email         VARCHAR(200) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'client',   -- admin | support | client
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW(),
    last_login    TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_users_auto_electro_dynamics_username ON users_facial_recognition_auto_electro_dynamics (username);
CREATE INDEX IF NOT EXISTS idx_users_auto_electro_dynamics_email    ON users_facial_recognition_auto_electro_dynamics (email);
CREATE INDEX IF NOT EXISTS idx_users_auto_electro_dynamics_user_id  ON users_facial_recognition_auto_electro_dynamics (user_id);

-- ============================================================
-- Drivers
-- ============================================================
CREATE TABLE IF NOT EXISTS drivers_auto_electro_dynamics (
    id              SERIAL PRIMARY KEY,
    driver_id       VARCHAR(20)  NOT NULL UNIQUE,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(200) UNIQUE,
    phone           VARCHAR(20),
    role            VARCHAR(20)  DEFAULT 'Driver',
    enrollment_date TIMESTAMP    DEFAULT NOW(),
    profile_photo   VARCHAR(200),
    status          VARCHAR(20)  DEFAULT 'active',
    embedding_path  VARCHAR(200),
    photo_count     INTEGER      DEFAULT 0
);

-- ============================================================
-- Recognition events (full history)
-- ============================================================
CREATE TABLE IF NOT EXISTS recognition_events_auto_electro_dynamics (
    id               SERIAL PRIMARY KEY,
    driver_id        INTEGER REFERENCES drivers_auto_electro_dynamics(id),
    driver_id_string VARCHAR(20),
    video_filename   VARCHAR(200),
    timestamp        TIMESTAMP DEFAULT NOW(),
    confidence       FLOAT,
    frame_number     INTEGER,
    status           VARCHAR(20),
    thumbnail_path   VARCHAR(200)
);

-- ============================================================
-- Recognition events (latest-per-video, upsert target)
-- ============================================================
CREATE TABLE IF NOT EXISTS recognition_events_latest_auto_electro_dynamics (
    id               SERIAL PRIMARY KEY,
    driver_id        INTEGER,
    driver_id_string VARCHAR(50),
    video_filename   VARCHAR(255) UNIQUE,
    frame_number     INTEGER,
    confidence       FLOAT,
    status           VARCHAR(50),
    thumbnail_path   VARCHAR(255),
    created_at       TIMESTAMP DEFAULT NOW(),
    updated_at       TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- Audit logs
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs_auto_electro_dynamics (
    id          SERIAL PRIMARY KEY,
    user_id     VARCHAR(36),
    username    VARCHAR(80),
    action      VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id   VARCHAR(80),
    details     TEXT,
    ip_address  VARCHAR(45),
    timestamp   TIMESTAMP DEFAULT NOW()
);

-- ============================================================
-- Custom fields (+ per-driver values)
-- ============================================================
CREATE TABLE IF NOT EXISTS custom_fields_auto_electro_dynamics (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    field_type  VARCHAR(30)  NOT NULL DEFAULT 'text',
    is_required BOOLEAN      DEFAULT FALSE,
    is_active   BOOLEAN      DEFAULT TRUE,
    options     TEXT,
    sort_order  INTEGER      DEFAULT 0,
    created_at  TIMESTAMP    DEFAULT NOW(),
    updated_at  TIMESTAMP    DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS driver_custom_field_values_auto_electro_dynamics (
    id              SERIAL PRIMARY KEY,
    driver_id       INTEGER NOT NULL REFERENCES drivers_auto_electro_dynamics(id),
    custom_field_id INTEGER NOT NULL REFERENCES custom_fields_auto_electro_dynamics(id),
    value           TEXT
);

-- ============================================================
-- Role permissions (per-role overrides)
-- ============================================================
CREATE TABLE IF NOT EXISTS role_permissions_auto_electro_dynamics (
    id         SERIAL PRIMARY KEY,
    role       VARCHAR(20) NOT NULL,
    permission VARCHAR(80) NOT NULL,
    granted    BOOLEAN     NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMP   DEFAULT NOW(),
    CONSTRAINT uq_role_perm_auto_electro_dynamics UNIQUE (role, permission)
);

-- ============================================================
-- Trips (loaded by pipeline/load_trips.py; app reads only)
-- ============================================================
CREATE TABLE IF NOT EXISTS trips_auto_electro_dynamics (
    id              SERIAL PRIMARY KEY,
    external_id     VARCHAR(64)  NOT NULL UNIQUE,
    vehicle         VARCHAR(100) NOT NULL,
    start_time      TIMESTAMP,
    end_time        TIMESTAMP,
    duration_min    FLOAT,
    start_location  TEXT,
    end_location    TEXT,
    start_lat       FLOAT,
    start_lng       FLOAT,
    end_lat         FLOAT,
    end_lng         FLOAT,
    start_zone_name VARCHAR(150),
    km              FLOAT,
    trip_type       VARCHAR(40),
    driver_name     VARCHAR(150),
    has_driver      BOOLEAN NOT NULL DEFAULT FALSE,
    is_excluded     BOOLEAN NOT NULL DEFAULT FALSE,
    source          VARCHAR(30) DEFAULT 'fmtrack',
    loaded_at       TIMESTAMP DEFAULT NOW(),
    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_external_id   ON trips_auto_electro_dynamics (external_id);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_vehicle       ON trips_auto_electro_dynamics (vehicle);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_start_time    ON trips_auto_electro_dynamics (start_time);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_driver_name   ON trips_auto_electro_dynamics (driver_name);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_has_driver    ON trips_auto_electro_dynamics (has_driver);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_is_excluded   ON trips_auto_electro_dynamics (is_excluded);
CREATE INDEX IF NOT EXISTS ix_trips_auto_electro_dynamics_vehicle_start ON trips_auto_electro_dynamics (vehicle, start_time);

-- ============================================================
-- Pipeline runs (audit trail for the data-load pipeline)
-- ============================================================
CREATE TABLE IF NOT EXISTS pipeline_runs_auto_electro_dynamics (
    id             SERIAL PRIMARY KEY,
    started_at     TIMESTAMP DEFAULT NOW(),
    finished_at    TIMESTAMP,
    status         VARCHAR(20) DEFAULT 'running',   -- running | success | failed
    range_from     TIMESTAMP,
    range_to       TIMESTAMP,
    trips_fetched  INTEGER DEFAULT 0,
    trips_inserted INTEGER DEFAULT 0,
    trips_updated  INTEGER DEFAULT 0,
    vehicles_seen  INTEGER DEFAULT 0,
    drivers_seen   INTEGER DEFAULT 0,
    message        TEXT
);

-- ============================================================
-- Geozones (loaded by pipeline/load_trips.py; app reads only)
-- ============================================================
CREATE TABLE IF NOT EXISTS geozones_auto_electro_dynamics (
    id            SERIAL PRIMARY KEY,
    external_id   VARCHAR(64) NOT NULL UNIQUE,
    name          VARCHAR(150),
    notes         TEXT,
    zone_type     VARCHAR(20),                       -- CIRCLE | POLYGON
    min_lat       FLOAT,
    max_lat       FLOAT,
    min_lng       FLOAT,
    max_lng       FLOAT,
    center_lat    FLOAT,
    center_lng    FLOAT,
    radius_m      FLOAT,
    geometry_json TEXT,
    loaded_at     TIMESTAMP DEFAULT NOW(),
    created_at    TIMESTAMP DEFAULT NOW(),
    updated_at    TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_geozones_auto_electro_dynamics_external_id ON geozones_auto_electro_dynamics (external_id);

-- ============================================================
-- Default admin user
-- Password: Admin@1234   — CHANGE THIS after first login!
-- ============================================================
INSERT INTO users_facial_recognition_auto_electro_dynamics (username, email, password_hash, role, is_active)
VALUES (
    'admin',
    'admin@autoelectrodynamics.local',
    'scrypt:32768:8:1$HMYgV7Ee6Vj3rZES$5fbad9c6c8c39c1b35f44ce78012e2eb25d1e05d1925263808fc5cc0ab080269e7d9e626f8534332c7051364881e43afca488f965a6e974169538330b8e10ca8',
    'admin',
    TRUE
)
ON CONFLICT (username) DO NOTHING;
