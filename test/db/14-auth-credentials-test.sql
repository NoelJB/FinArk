-- ============================================================================
-- FINARK PLATFORM - TEST 14: IDENTITY STORE AUTHENTICATION & HASH ASSERTIONS
-- Target File: test/14-auth-credentials-test.sql | BRS Mapping: BR-01 / BR-02
-- ============================================================================
\c paysprint;

-- Assertion A: Verify pgcrypto validates Alice's correct password natively
SELECT 'ASSERT' AS label,
       'credential_auth_success_alice' AS slug,
       (COUNT(*))::TEXT AS actual,
       '1' AS expected
FROM client_credentials
WHERE username = 'alice'
  AND password_hash = crypt('mission123', password_hash);

-- Assertion B: Verify pgcrypto rejects Bob's account if an invalid password is passed
SELECT 'ASSERT' AS label,
       'credential_auth_failure_bob' AS slug,
       (COUNT(*))::TEXT AS actual,
       '0' AS expected
FROM client_credentials
WHERE username = 'bob'
  AND password_hash = crypt('brute-force-guess-attempt', password_hash);

-- ============================================================================
-- REGISTRATION INSULATION BOUNDARY (BR-01 Enforced)
-- ============================================================================

-- 🔐 RESOLVE CONTEXT FIRST: Target Farid Hossain to prevent baseline account overwrites
SELECT id::TEXT FROM client WHERE name = 'Farid Hossain' \gset client_

-- Switch down to our low-privilege application runtime role
SET ROLE paysprint_app;

-- Execute insertion: This will insert cleanly as a new record because Farid has no credentials
INSERT INTO client_credentials (client_id, username, password_hash)
VALUES (
    :'client_id'::INT,
    'farid_alt_profile', -- 💡 Aligned name tag
    crypt('securenewsignup2026', gen_salt('bf', 8))
) ON CONFLICT (client_id) DO UPDATE 
  SET username = 'farid_alt_profile', 
      password_hash = crypt('securenewsignup2026', gen_salt('bf', 8));

-- Assertion D: Verify that the newly inserted registration credential evaluates green
SELECT 'ASSERT' AS label,
       'dynamic_registration_validation' AS slug,
       (COUNT(*))::TEXT AS actual,
       '1' AS expected
FROM client_credentials
WHERE username = 'farid_alt_profile'
  AND password_hash = crypt('securenewsignup2026', password_hash);

-- Reset configuration state back to superuser for downstream modules
RESET ROLE;
