-- ============================================
-- LaporanMRFH - SETUP FINAL ADMIN (2 akun)
--  1) bundamasmuh@gmail.com    / bismillah   -> username 'admin'   (role admin)
--  2) bluenderender@gmail.com  / donutspapaya -> username 'admin2' (role admin)
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- Idempoten: aman dijalankan berulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===== 0) Perbaiki SEMUA baris auth.users yang masih NULL token =====
UPDATE auth.users
SET
  confirmation_token         = COALESCE(confirmation_token, ''),
  recovery_token             = COALESCE(recovery_token, ''),
  email_change_token_new     = COALESCE(email_change_token_new, ''),
  email_change_token_current = COALESCE(email_change_token_current, ''),
  email_change               = COALESCE(email_change, '');

-- ===== 1) Bersihkan baris lama kedua akun =====
DELETE FROM auth.identities
WHERE user_id IN (SELECT id FROM auth.users
                  WHERE email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com'));

DELETE FROM public.users
WHERE auth_id IN (SELECT id FROM auth.users
                  WHERE email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com'));

DELETE FROM auth.users
WHERE email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com');

DELETE FROM public.users WHERE username IN ('admin', 'admin2');

-- ===== 2) Buat ulang AKUN 1: bundamasmuh@gmail.com (admin) =====
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  confirmation_token, recovery_token, email_change_token_new, email_change_token_current, email_change,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data)
VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated',
  'bundamasmuh@gmail.com',
  crypt('bismillah', gen_salt('bf')),
  '', '', '', '', '',
  now(), now(), now(),
  '{"provider":"email","providers":["email"]}',
  '{"username":"admin"}'
);

-- ===== 3) Buat ulang AKUN 2 (bluenderender@gmail.com / admin2) =====
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password,
  confirmation_token, recovery_token, email_change_token_new, email_change_token_current, email_change,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data)
VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated',
  'bluenderender@gmail.com',
  crypt('donutspapaya', gen_salt('bf')),
  '', '', '', '', '',
  now(), now(), now(),
  '{"provider":"email","providers":["email"]}',
  '{"username":"admin2"}'
);

-- ===== 4) Identitas email untuk kedua akun =====
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
SELECT gen_random_uuid(), id,
    jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true),
    'email', id::text, now(), now(), now()
FROM auth.users
WHERE email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com')
ON CONFLICT DO NOTHING;

-- ===== 5) Link public.users (role admin untuk keduanya) =====
INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin',  'Administrator', 'admin', id, now()
FROM auth.users WHERE email = 'bundamasmuh@gmail.com'
ON CONFLICT (username) DO UPDATE
SET name = EXCLUDED.name, role = EXCLUDED.role, auth_id = EXCLUDED.auth_id, last_seen = EXCLUDED.last_seen;

INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin2', 'Administrator', 'admin', id, now()
FROM auth.users WHERE email = 'bluenderender@gmail.com'
ON CONFLICT (username) DO UPDATE
SET name = EXCLUDED.name, role = EXCLUDED.role, auth_id = EXCLUDED.auth_id, last_seen = EXCLUDED.last_seen;

-- ===== 6) VERIFIKASI =====
SELECT u.email,
       p.username, p.role, p.name,
       i.provider,
       (u.confirmation_token = '') AS token_ok
FROM auth.users u
LEFT JOIN public.users p    ON p.auth_id = u.id
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE u.email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com')
ORDER BY u.email;

-- Hasil yang diharapkan (2 baris):
--  bundamasmuh@gmail.com  | admin  | admin | Administrator | email | true
--  bluenderender@gmail.com| admin2 | admin | Administrator | email | true