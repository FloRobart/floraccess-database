-- ============================================
-- Migration: 20261110120000_add_login_requests_without_login_on_users
-- Description: Number of login codes sent to a user since his last
--              successful login. Once 5 codes were sent without a
--              successful login, the API waits longer between two
--              codes (10 minutes instead of 1 by default), and after
--              10 codes it blocks the logins of the account for a
--              while, so that the codes of an account can not be
--              guessed by requesting new ones in a loop.
--              A successful login sets it back to 0.
-- Author: Floris Robart
-- ============================================



-- migrate:up

-- The existing users start at 0: their next codes keep the base time between two codes
ALTER TABLE users ADD COLUMN login_requests_without_login INTEGER NOT NULL DEFAULT 0;



-- migrate:down

ALTER TABLE users DROP COLUMN IF EXISTS login_requests_without_login;
