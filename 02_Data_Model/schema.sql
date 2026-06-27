-- ============================================================
-- PROJECT SENTINEL: Enterprise Fraud Intelligence Platform
-- Data Model: 20-Table Schema
-- Version: 1.0 | PostgreSQL Compatible
-- ============================================================

-- ============================================================
-- CORE IDENTITY TABLES
-- ============================================================

CREATE TABLE drivers (
    driver_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id         VARCHAR(50) UNIQUE NOT NULL,
    first_name          VARCHAR(100) NOT NULL,
    last_name           VARCHAR(100) NOT NULL,
    email               VARCHAR(255) UNIQUE NOT NULL,
    phone_number        VARCHAR(20) UNIQUE NOT NULL,
    date_of_birth       DATE NOT NULL,
    ssn_hash            CHAR(64),                          -- SHA-256 hash
    license_number      VARCHAR(50),
    license_state       CHAR(2),
    license_expiry      DATE,
    onboarding_date     TIMESTAMP WITH TIME ZONE NOT NULL,
    status              VARCHAR(30) NOT NULL DEFAULT 'active',  -- active, suspended, deactivated, under_review
    risk_tier           VARCHAR(10) DEFAULT 'low',             -- low, medium, high, critical
    risk_score          DECIMAL(5,2) DEFAULT 0.0,
    city                VARCHAR(100),
    state               CHAR(2),
    zip_code            VARCHAR(10),
    referral_source     VARCHAR(50),
    referring_driver_id UUID REFERENCES drivers(driver_id),
    total_deliveries    INTEGER DEFAULT 0,
    total_earnings      DECIMAL(12,2) DEFAULT 0.0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE customers (
    customer_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id         VARCHAR(50) UNIQUE NOT NULL,
    email               VARCHAR(255) UNIQUE NOT NULL,
    phone_number        VARCHAR(20),
    full_name           VARCHAR(200),
    date_of_birth       DATE,
    registration_date   TIMESTAMP WITH TIME ZONE NOT NULL,
    status              VARCHAR(30) DEFAULT 'active',
    risk_tier           VARCHAR(10) DEFAULT 'low',
    risk_score          DECIMAL(5,2) DEFAULT 0.0,
    city                VARCHAR(100),
    state               CHAR(2),
    is_subscriber       BOOLEAN DEFAULT FALSE,
    subscription_since  TIMESTAMP WITH TIME ZONE,
    lifetime_orders     INTEGER DEFAULT 0,
    lifetime_gmv        DECIMAL(12,2) DEFAULT 0.0,
    chargeback_count    INTEGER DEFAULT 0,
    refund_count        INTEGER DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- VEHICLE & VERIFICATION TABLES
-- ============================================================

CREATE TABLE vehicle_information (
    vehicle_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id           UUID NOT NULL REFERENCES drivers(driver_id),
    make                VARCHAR(50),
    model               VARCHAR(50),
    year                SMALLINT,
    color               VARCHAR(30),
    vin                 VARCHAR(17) UNIQUE,
    license_plate       VARCHAR(20),
    plate_state         CHAR(2),
    insurance_provider  VARCHAR(100),
    insurance_expiry    DATE,
    inspection_date     DATE,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE identity_verification (
    verification_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type         VARCHAR(20) NOT NULL,   -- driver, customer
    entity_id           UUID NOT NULL,
    verification_type   VARCHAR(50) NOT NULL,   -- document, selfie, ssn, biometric
    provider            VARCHAR(100),           -- Persona, Jumio, Onfido
    status              VARCHAR(30) NOT NULL,   -- passed, failed, pending, manual_review
    confidence_score    DECIMAL(5,2),
    failure_reason      VARCHAR(255),
    document_type       VARCHAR(50),
    document_number_hash CHAR(64),
    attempt_number      SMALLINT DEFAULT 1,
    ip_address          INET,
    device_id           UUID,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- DEVICE & SESSION TABLES
-- ============================================================

CREATE TABLE devices (
    device_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    device_fingerprint  VARCHAR(255) UNIQUE NOT NULL,
    device_type         VARCHAR(20),            -- ios, android, web
    os_version          VARCHAR(50),
    app_version         VARCHAR(20),
    manufacturer        VARCHAR(100),
    model               VARCHAR(100),
    is_emulator         BOOLEAN DEFAULT FALSE,
    is_rooted           BOOLEAN DEFAULT FALSE,
    is_vpn_detected     BOOLEAN DEFAULT FALSE,
    risk_score          DECIMAL(5,2) DEFAULT 0.0,
    first_seen          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_accounts_linked INTEGER DEFAULT 0,
    flagged_at          TIMESTAMP WITH TIME ZONE
);

CREATE TABLE login_events (
    login_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    device_id           UUID REFERENCES devices(device_id),
    ip_address          INET NOT NULL,
    latitude            DECIMAL(9,6),
    longitude           DECIMAL(9,6),
    city                VARCHAR(100),
    country             CHAR(2),
    is_vpn              BOOLEAN DEFAULT FALSE,
    is_tor              BOOLEAN DEFAULT FALSE,
    login_success       BOOLEAN NOT NULL,
    failure_reason      VARCHAR(100),
    user_agent          TEXT,
    login_timestamp     TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE TABLE session_events (
    session_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    device_id           UUID REFERENCES devices(device_id),
    login_id            UUID REFERENCES login_events(login_id),
    session_start       TIMESTAMP WITH TIME ZONE NOT NULL,
    session_end         TIMESTAMP WITH TIME ZONE,
    duration_seconds    INTEGER,
    screen_views        INTEGER DEFAULT 0,
    actions_count       INTEGER DEFAULT 0,
    ip_address          INET,
    is_suspicious       BOOLEAN DEFAULT FALSE,
    risk_signals        JSONB DEFAULT '{}'
);

-- ============================================================
-- ORDER & DELIVERY TABLES
-- ============================================================

CREATE TABLE orders (
    order_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_order_id   VARCHAR(50) UNIQUE NOT NULL,
    customer_id         UUID NOT NULL REFERENCES customers(customer_id),
    driver_id           UUID REFERENCES drivers(driver_id),
    merchant_id         UUID,
    order_status        VARCHAR(30) NOT NULL DEFAULT 'placed',
    order_placed_at     TIMESTAMP WITH TIME ZONE NOT NULL,
    order_accepted_at   TIMESTAMP WITH TIME ZONE,
    order_picked_up_at  TIMESTAMP WITH TIME ZONE,
    order_delivered_at  TIMESTAMP WITH TIME ZONE,
    order_cancelled_at  TIMESTAMP WITH TIME ZONE,
    subtotal            DECIMAL(10,2) NOT NULL,
    delivery_fee        DECIMAL(8,2) DEFAULT 0.0,
    tip_amount          DECIMAL(8,2) DEFAULT 0.0,
    promo_discount      DECIMAL(8,2) DEFAULT 0.0,
    total_amount        DECIMAL(10,2) NOT NULL,
    delivery_address    TEXT,
    delivery_lat        DECIMAL(9,6),
    delivery_lng        DECIMAL(9,6),
    pickup_lat          DECIMAL(9,6),
    pickup_lng          DECIMAL(9,6),
    is_fraud            BOOLEAN DEFAULT FALSE,
    fraud_type          VARCHAR(100),
    risk_score          DECIMAL(5,2) DEFAULT 0.0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE gps_logs (
    gps_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID REFERENCES orders(order_id),
    driver_id           UUID NOT NULL REFERENCES drivers(driver_id),
    latitude            DECIMAL(9,6) NOT NULL,
    longitude           DECIMAL(9,6) NOT NULL,
    accuracy_meters     DECIMAL(7,2),
    altitude            DECIMAL(8,2),
    speed_kmh           DECIMAL(6,2),
    bearing             DECIMAL(5,2),
    is_mocked           BOOLEAN DEFAULT FALSE,
    provider            VARCHAR(50),             -- gps, network, fused
    recorded_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- PAYMENT TABLES
-- ============================================================

CREATE TABLE payments (
    payment_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID REFERENCES orders(order_id),
    customer_id         UUID NOT NULL REFERENCES customers(customer_id),
    payment_method_type VARCHAR(30) NOT NULL,    -- card, wallet, bnpl, cash
    card_bin            CHAR(6),
    card_last_four      CHAR(4),
    card_type           VARCHAR(20),             -- visa, mc, amex, discover
    bank_name           VARCHAR(100),
    is_prepaid          BOOLEAN DEFAULT FALSE,
    billing_zip         VARCHAR(10),
    billing_country     CHAR(2),
    amount              DECIMAL(10,2) NOT NULL,
    currency            CHAR(3) DEFAULT 'USD',
    payment_status      VARCHAR(30) NOT NULL,
    processor_response  VARCHAR(50),
    is_chargeback       BOOLEAN DEFAULT FALSE,
    chargeback_date     DATE,
    chargeback_reason   VARCHAR(100),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE chargebacks (
    chargeback_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id          UUID NOT NULL REFERENCES payments(payment_id),
    customer_id         UUID NOT NULL REFERENCES customers(customer_id),
    order_id            UUID REFERENCES orders(order_id),
    amount              DECIMAL(10,2) NOT NULL,
    reason_code         VARCHAR(50),
    reason_description  VARCHAR(255),
    filed_date          DATE NOT NULL,
    resolution_date     DATE,
    resolution          VARCHAR(30),             -- won, lost, pending
    is_friendly_fraud   BOOLEAN DEFAULT FALSE,
    evidence_submitted  BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- FRAUD & RISK TABLES
-- ============================================================

CREATE TABLE risk_signals (
    signal_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    signal_name         VARCHAR(100) NOT NULL,
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    signal_value        DECIMAL(10,4),
    signal_category     VARCHAR(50),             -- device, location, behavioral, network, financial
    severity            VARCHAR(10),             -- info, low, medium, high, critical
    triggered_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at          TIMESTAMP WITH TIME ZONE,
    is_active           BOOLEAN DEFAULT TRUE,
    metadata            JSONB DEFAULT '{}'
);

CREATE TABLE fraud_alerts (
    alert_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    alert_type          VARCHAR(100) NOT NULL,
    fraud_category      VARCHAR(50),
    risk_score          DECIMAL(5,2) NOT NULL,
    confidence          DECIMAL(5,2),
    signals_triggered   JSONB DEFAULT '[]',
    triggered_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status              VARCHAR(30) DEFAULT 'open',  -- open, in_review, closed, false_positive
    assigned_to         VARCHAR(100),
    resolved_at         TIMESTAMP WITH TIME ZONE,
    resolution          VARCHAR(50),
    resolution_notes    TEXT
);

CREATE TABLE investigations (
    investigation_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_number         VARCHAR(50) UNIQUE NOT NULL,
    alert_id            UUID REFERENCES fraud_alerts(alert_id),
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    investigator_id     VARCHAR(100),
    priority            VARCHAR(10) NOT NULL DEFAULT 'medium',
    status              VARCHAR(30) NOT NULL DEFAULT 'open',
    fraud_type          VARCHAR(100),
    estimated_loss      DECIMAL(12,2),
    actual_loss         DECIMAL(12,2),
    opened_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    first_action_at     TIMESTAMP WITH TIME ZONE,
    closed_at           TIMESTAMP WITH TIME ZONE,
    resolution          VARCHAR(50),             -- substantiated, unsubstantiated, inconclusive
    action_taken        VARCHAR(100),            -- deactivated, warned, cleared, escalated
    evidence_links      JSONB DEFAULT '[]',
    notes               TEXT,
    audit_trail         JSONB DEFAULT '[]'
);

CREATE TABLE appeals (
    appeal_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    investigation_id    UUID NOT NULL REFERENCES investigations(investigation_id),
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    appeal_reason       TEXT NOT NULL,
    filed_at            TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_by         VARCHAR(100),
    decision            VARCHAR(30),             -- upheld, reversed, partial_reinstatement
    decision_reason     TEXT,
    decided_at          TIMESTAMP WITH TIME ZONE,
    reinstatement_conditions TEXT
);

-- ============================================================
-- INCENTIVE & SOCIAL TABLES
-- ============================================================

CREATE TABLE referrals (
    referral_id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id         UUID NOT NULL,
    referrer_type       VARCHAR(20) NOT NULL,    -- driver, customer
    referred_id         UUID,
    referred_type       VARCHAR(20),
    referral_code       VARCHAR(50) NOT NULL,
    status              VARCHAR(30) DEFAULT 'pending',
    bonus_amount        DECIMAL(8,2),
    bonus_paid          BOOLEAN DEFAULT FALSE,
    bonus_paid_at       TIMESTAMP WITH TIME ZONE,
    is_fraudulent       BOOLEAN DEFAULT FALSE,
    fraud_reason        VARCHAR(100),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE incentives (
    incentive_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id           UUID NOT NULL REFERENCES drivers(driver_id),
    incentive_type      VARCHAR(50) NOT NULL,    -- sign_up_bonus, quest, surge, referral
    amount              DECIMAL(8,2) NOT NULL,
    status              VARCHAR(30) DEFAULT 'pending',
    qualifying_event_id UUID,
    is_fraud_review     BOOLEAN DEFAULT FALSE,
    paid_at             TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE promotions (
    promo_id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    promo_code          VARCHAR(50) UNIQUE NOT NULL,
    promo_type          VARCHAR(50),
    discount_type       VARCHAR(20),             -- flat, percent
    discount_value      DECIMAL(8,2),
    max_uses            INTEGER,
    uses_per_user       INTEGER DEFAULT 1,
    total_uses          INTEGER DEFAULT 0,
    start_date          TIMESTAMP WITH TIME ZONE,
    end_date            TIMESTAMP WITH TIME ZONE,
    is_active           BOOLEAN DEFAULT TRUE,
    is_flagged          BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- SUPPORT & RATING TABLES
-- ============================================================

CREATE TABLE customer_support (
    ticket_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type         VARCHAR(20) NOT NULL,
    entity_id           UUID NOT NULL,
    order_id            UUID REFERENCES orders(order_id),
    contact_type        VARCHAR(30),             -- chat, call, email
    issue_category      VARCHAR(100),
    issue_description   TEXT,
    resolution_type     VARCHAR(50),             -- refund, credit, no_action, escalated
    resolution_amount   DECIMAL(8,2),
    opened_at           TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    resolved_at         TIMESTAMP WITH TIME ZONE,
    agent_id            VARCHAR(100),
    is_fraud_related    BOOLEAN DEFAULT FALSE
);

CREATE TABLE driver_ratings (
    rating_id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id            UUID NOT NULL REFERENCES orders(order_id),
    driver_id           UUID NOT NULL REFERENCES drivers(driver_id),
    customer_id         UUID NOT NULL REFERENCES customers(customer_id),
    rating              SMALLINT CHECK (rating BETWEEN 1 AND 5),
    feedback_text       TEXT,
    is_flagged          BOOLEAN DEFAULT FALSE,
    flag_reason         VARCHAR(100),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

-- Driver indexes
CREATE INDEX idx_drivers_status ON drivers(status);
CREATE INDEX idx_drivers_risk_score ON drivers(risk_score DESC);
CREATE INDEX idx_drivers_phone ON drivers(phone_number);

-- Order indexes
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_driver_id ON orders(driver_id);
CREATE INDEX idx_orders_placed_at ON orders(order_placed_at);
CREATE INDEX idx_orders_is_fraud ON orders(is_fraud) WHERE is_fraud = TRUE;

-- GPS indexes
CREATE INDEX idx_gps_driver_id ON gps_logs(driver_id);
CREATE INDEX idx_gps_order_id ON gps_logs(order_id);
CREATE INDEX idx_gps_recorded_at ON gps_logs(recorded_at);

-- Login event indexes
CREATE INDEX idx_login_entity ON login_events(entity_type, entity_id);
CREATE INDEX idx_login_device ON login_events(device_id);
CREATE INDEX idx_login_ip ON login_events(ip_address);

-- Risk signal indexes
CREATE INDEX idx_signals_entity ON risk_signals(entity_type, entity_id);
CREATE INDEX idx_signals_category ON risk_signals(signal_category);
CREATE INDEX idx_signals_active ON risk_signals(is_active) WHERE is_active = TRUE;

-- Investigation indexes
CREATE INDEX idx_investigations_status ON investigations(status);
CREATE INDEX idx_investigations_priority ON investigations(priority);
CREATE INDEX idx_investigations_entity ON investigations(entity_type, entity_id);

-- ============================================================
-- SUMMARY VIEWS
-- ============================================================

CREATE OR REPLACE VIEW v_driver_risk_summary AS
SELECT
    d.driver_id,
    d.external_id,
    d.first_name || ' ' || d.last_name AS full_name,
    d.status,
    d.risk_tier,
    d.risk_score,
    d.total_deliveries,
    d.total_earnings,
    COUNT(DISTINCT fa.alert_id) AS open_alerts,
    COUNT(DISTINCT i.investigation_id) AS total_investigations,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.is_fraud = TRUE) AS confirmed_fraud_orders,
    MAX(fa.triggered_at) AS last_alert_date
FROM drivers d
LEFT JOIN fraud_alerts fa ON fa.entity_id = d.driver_id AND fa.status = 'open'
LEFT JOIN investigations i ON i.entity_id = d.driver_id
LEFT JOIN orders o ON o.driver_id = d.driver_id
GROUP BY d.driver_id;

CREATE OR REPLACE VIEW v_daily_fraud_metrics AS
SELECT
    DATE_TRUNC('day', order_placed_at) AS metric_date,
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (WHERE is_fraud = TRUE) AS fraud_orders,
    SUM(total_amount) FILTER (WHERE is_fraud = TRUE) AS fraud_losses,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_fraud = TRUE) / COUNT(*), 2) AS fraud_rate_pct,
    AVG(risk_score) AS avg_risk_score
FROM orders
GROUP BY 1
ORDER BY 1 DESC;
