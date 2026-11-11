-- ============================================
-- Migration: 20261108120000_baseline
-- Description: Initial schema of the FlorAccess database
--              (updated_at function, tables, triggers and the
--              authentication methods the API relies on).
--              It reproduces the schema built by the former
--              Database/ folder of the API, migrations 502 to 505
--              included, with the columns in the same order.
--              On an existing production database, this migration
--              must be marked as applied instead of being executed
--              (see README.md, "Basculer une base existante").
-- Author: Floris Robart
-- ============================================



-- migrate:up

-- ------------------------------------------
-- Functions
-- ------------------------------------------

-- Function to update the updated_at field
-- This function will be called by a trigger before each update
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



-- ------------------------------------------
-- Table: auth_methods
-- ------------------------------------------

-- Table to store authentication methods
CREATE TABLE auth_methods (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    immuable_method_name VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT auth_methods_immuable_method_name_key UNIQUE (immuable_method_name)
);



-- ------------------------------------------
-- Table: users
-- ------------------------------------------

-- Table to store user information
CREATE TABLE users (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    email VARCHAR(320) NOT NULL,
    pseudo VARCHAR(255) NOT NULL,

    auth_methods_id INTEGER NOT NULL,
    is_connected BOOLEAN DEFAULT TRUE,
    is_verified_email BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    last_ip VARCHAR(512),

    email_verify_token_hash VARCHAR(1024),
    secret_hash VARCHAR(1024),
    token_hash VARCHAR(1024),

    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,

    -- Former migration 502: logout date, the JWT issued before it are rejected
    last_logout_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Former migration 503: access to the admins routes
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,

    -- Former migration 504: expiration and limited attempts of the login code
    -- login_requested_at: date of the last login code sent, used for the expiration and the cooldown between two requests
    -- login_code_attempts: number of confirmations already tried on the current login code
    login_requested_at TIMESTAMPTZ,
    login_code_attempts INTEGER NOT NULL DEFAULT 0,

    -- Former migration 505: block of the logins from the login code email
    -- login_block_token_hash: hash of the token carried by the block link of the last login code email
    -- login_blocked_until: end of the block (a date rather than a boolean, so that the block ends by itself)
    login_block_token_hash VARCHAR(1024),
    login_blocked_until TIMESTAMPTZ,

    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT auth_methods_id_fkey FOREIGN KEY (auth_methods_id) REFERENCES auth_methods(id) ON DELETE RESTRICT
);



-- ------------------------------------------
-- Triggers: keep updated_at up to date
-- ------------------------------------------

CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_auth_methods_updated_at
BEFORE UPDATE ON auth_methods
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();



-- ------------------------------------------
-- Reference data: authentication methods
-- ------------------------------------------

-- Required by the API: every user references one of them (DEFAULT_AUTH_METHOD of the API).
-- Inserted in this order so that PASSWORD gets the id 1 and EMAIL_CODE the id 2, as before.
INSERT INTO auth_methods (immuable_method_name, display_name)
VALUES ('PASSWORD', 'Password'), ('EMAIL_CODE', 'Code');



-- migrate:down

-- Dropping a table also drops its triggers.
-- users first: it references auth_methods.
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS auth_methods;

DROP FUNCTION IF EXISTS update_updated_at();
