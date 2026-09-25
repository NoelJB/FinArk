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

-- 🔐 RESOLVE CONTEXT FIRST: Capture Alice's numeric ID using administrative authority
-- and store it inside a temporary session configuration variable.
SELECT id::TEXT FROM client WHERE name = 'Alice Johnson' \gset client_

-- Switch down to our low-privilege application runtime roleuser
SET ROLE paysprint_app;

-- Execute insertion: Read the pre-resolved integer variable directly to bypass 
-- unauthorized table scans on the parent client registry.
INSERT INTO client_credentials (client_id, username, password_hash)
VALUES (
    :'client_id'::INT,
    'alice_alt_profile',
    crypt('securenewsignup2026', gen_salt('bf', 8))
) ON CONFLICT (client_id) DO UPDATE 
  SET username = 'alice_alt_profile', 
      password_hash = crypt('securenewsignup2026', gen_salt('bf', 8));

-- Assertion D: Verify that the newly inserted registration credential evaluates green under paysprint_app
SELECT 'ASSERT' AS label,
       'dynamic_registration_validation' AS slug,
       (COUNT(*))::TEXT AS actual,
       '1' AS expected
FROM client_credentials
WHERE username = 'alice_alt_profile'
  AND password_hash = crypt('securenewsignup2026', password_hash);

-- Reset configuration state back to superuser for downstream modules
RESET ROLE;
