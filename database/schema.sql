-- ============================================
-- VIZ-AI DATABASE SCHEMA
-- Master Database: viz_ai_master
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    oauth_provider VARCHAR(50) NOT NULL,
    oauth_id VARCHAR(255) UNIQUE NOT NULL,
    oauth_access_token_encrypted TEXT NOT NULL,
    oauth_refresh_token_encrypted TEXT,
    
    name VARCHAR(255) NOT NULL,
    avatar_url TEXT,
    timezone VARCHAR(50) DEFAULT 'Asia/Kolkata',
    
    role VARCHAR(50) NOT NULL DEFAULT 'USER' CHECK (role IN ('USER', 'ADMIN')),
    voice_preference VARCHAR(50) DEFAULT 'neutral',
    notification_channels JSONB DEFAULT '{"email": true, "sms": false}'::jsonb,
    preferred_language VARCHAR(10) DEFAULT 'en',
    theme VARCHAR(20) DEFAULT 'dark' CHECK (theme IN ('dark', 'light')),
    
    daily_memory_update_limit INT DEFAULT 100,
    daily_memory_updates_used INT DEFAULT 0,
    memory_update_reset_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    is_active BOOLEAN DEFAULT true,
    soft_deleted_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    subscription_tier VARCHAR(50) DEFAULT 'free',
    billing_email VARCHAR(255),
    gdpr_data_export_requested_at TIMESTAMP,
    gdpr_deletion_scheduled_at TIMESTAMP
);

CREATE INDEX idx_users_oauth ON users(oauth_provider, oauth_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

-- ============================================
-- 2. API KEYS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) NOT NULL CHECK (service_type IN ('chat', 'coding', 'image', 'voice', 'research')),
    
    api_key_encrypted TEXT NOT NULL,
    api_key_hash VARCHAR(255) UNIQUE NOT NULL,
    
    global_daily_limit INT,
    daily_usage_tokens INT DEFAULT 0,
    daily_usage_cost DECIMAL(10, 4) DEFAULT 0.00,
    monthly_usage_tokens INT DEFAULT 0,
    monthly_usage_cost DECIMAL(12, 4) DEFAULT 0.00,
    usage_reset_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    is_active BOOLEAN DEFAULT true,
    is_paused BOOLEAN DEFAULT false,
    pause_reason VARCHAR(255),
    
    has_fallback BOOLEAN DEFAULT false,
    fallback_api_key_id UUID REFERENCES api_keys(id),
    
    last_used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, service_name, service_type)
);

CREATE INDEX idx_api_keys_user_active ON api_keys(user_id, is_active);
CREATE INDEX idx_api_keys_service ON api_keys(user_id, service_type);
CREATE INDEX idx_api_keys_hash ON api_keys(api_key_hash);

-- ============================================
-- 3. RATE LIMIT COUNTERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS rate_limit_counters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    
    requests_per_minute INT DEFAULT 0,
    requests_per_hour INT DEFAULT 0,
    requests_per_day INT DEFAULT 0,
    
    api_calls_per_day INT DEFAULT 0,
    memory_updates_per_day INT DEFAULT 0,
    
    minute_window_reset_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    hour_window_reset_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    day_window_reset_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rate_limit_user ON rate_limit_counters(user_id);

-- ============================================
-- 4. OAUTH TOKENS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS oauth_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    provider VARCHAR(50) NOT NULL,
    provider_account_id VARCHAR(255) NOT NULL,
    
    access_token_encrypted TEXT NOT NULL,
    refresh_token_encrypted TEXT,
    token_expires_at TIMESTAMP,
    
    is_active BOOLEAN DEFAULT true,
    is_revoked BOOLEAN DEFAULT false,
    revoked_at TIMESTAMP,
    
    scopes VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, provider, provider_account_id)
);

CREATE INDEX idx_oauth_tokens_user ON oauth_tokens(user_id);
CREATE INDEX idx_oauth_tokens_active ON oauth_tokens(user_id, is_active);

-- ============================================
-- 5. AUDIT LOGS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id VARCHAR(255),
    
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_action CHECK (action IN (
        'login', 'logout', 'api_key_added', 'api_key_rotated', 'api_key_deleted',
        'automation_executed', 'automation_created', 'automation_deleted',
        'memory_updated', 'chat_created', 'chat_deleted',
        'oauth_connected', 'oauth_revoked'
    ))
);

CREATE INDEX idx_audit_user_action ON audit_logs(user_id, action);
CREATE INDEX idx_audit_created ON audit_logs(created_at DESC);

-- ============================================
-- 6. TENANT DATABASE CREATION TRIGGER
-- ============================================

CREATE OR REPLACE FUNCTION create_user_tenant_database()
RETURNS TRIGGER AS $$
BEGIN
    -- This will be handled by application code for now
    -- In production, use a background job or function to create tenant DB
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_tenant_on_user_creation
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION create_user_tenant_database();
