-- ============================================
-- LaporanMRFH - Akun ADMIN kedua: bluenderender@gmail.com
-- Email: bluenderender@gmail.com / Password: donutspapaya
-- Username di aplikasi: admin2, Role: admin
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- CATATAN:
-- 1. Rebuild bersih (auth.users + auth.identities + public.users).
-- 2. Kolom token diisi string kosong langsung saat insert
--    (menghindari bug "500 Database error querying schema").
-- 3. Idempoten - aman dijalankan ulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===== 1) Hapus akun lama + baris terkait =====
DELETE FROM auth.identities
WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'bluenderender@gmail.com');

DELETE FROM public.users
WHERE auth_id IN (SELECT id FROM auth.users WHERE email = 'bluenderender@gmail.com');

DELETE FROM auth.users WHERE email = 'bluenderender@gmail.com';

-- ===== 2) Buat akun admin kedua yang bersih (token NULL dicegah) =====
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

-- ===== 3) Buat identity email (WAJIB agar signInWithPassword berhasil) =====
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
SELECT gen_random_uuid(), id,
    jsonb_build_object('sub', id::text, 'email', 'bluenderender@gmail.com', 'email_verified', true),
    'email', id::text, now(), now(), now()
FROM auth.users
WHERE email = 'bluenderender@gmail.com'
ON CONFLICT DO NOTHING;

-- ===== 4) Link public.users (admin kedua, username admin2) =====
INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin2', 'Administrator', 'admin', id, now()
FROM auth.users
WHERE email = 'bluenderender@gmail.com'
ON CONFLICT (username) DO UPDATE
SET name = EXCLUDED.name, role = EXCLUDED.role, auth_id = EXCLUDED.auth_id, last_seen = EXCLUDED.last_seen;

-- ===== 5) Verifikasi hasil =====
SELECT u.email, p.username, p.role, p.name, i.provider
FROM auth.users u
LEFT JOIN public.users p    ON p.auth_id = u.id
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE u.email IN ('bluenderender@gmail.com', 'bundamasmuh@gmail.com')

-- Harus tampil 2 baris:
--  bluenderender@gmail.com | admin2 | admin | Administrator | email
--  bundamasmuh@gmail.com   | admin  | admin | Administrator | email