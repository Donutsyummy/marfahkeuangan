-- ============================================
-- LaporanMRFH - Perbaiki Akun ADMIN bluenderender@gmail.com
-- Email: bluenderender@gmail.com / Password: faiqbaik
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- CATATAN:
-- 1. Rebuild bersih akun bluenderender@gmail.com yang gagal login
--    (auth.users + auth.identities) + baris public.users (role admin).
-- 2. auth.identities WAJIB ada di Supabase versi baru. Tanpa baris ini,
--    signInWithPassword akan gagal "Invalid login credentials".
-- 3. Idempoten - aman dijalankan ulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===== 1) Hapus akun lama + baris terkait =====
DELETE FROM auth.identities
WHERE user_id IN (SELECT id FROM auth.users WHERE email = 'bluenderender@gmail.com');

DELETE FROM public.users
WHERE auth_id IN (SELECT id FROM auth.users WHERE email = 'bluenderender@gmail.com');

DELETE FROM auth.users WHERE email = 'bluenderender@gmail.com';

DELETE FROM public.users WHERE username = 'admin';

-- ===== 2) Buat ulang akun admin yang bersih =====
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data)
VALUES (gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'bluenderender@gmail.com',
    crypt('faiqbaik', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"username":"admin"}'
);

-- Link public.users admin ke akun yang baru dibuat
INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin', 'Administrator', 'admin', id, now()
FROM auth.users
WHERE email = 'bluenderender@gmail.com'
LIMIT 1;

-- ===== 3) Buat identity email (WAJIB agar signInWithPassword berhasil) =====
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
SELECT gen_random_uuid(), id,
    jsonb_build_object('sub', id::text, 'email', 'bluenderender@gmail.com', 'email_verified', true),
    'email', id::text, now(), now(), now()
FROM auth.users
WHERE email = 'bluenderender@gmail.com'
LIMIT 1;

-- ===== 4) Verifikasi hasil =====
SELECT u.email, u.id AS auth_id, p.username, p.role, p.name,
       i.provider, i.provider_id, i.identity_data->>'email' AS identity_email
FROM auth.users u
LEFT JOIN public.users p    ON p.auth_id = u.id
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE u.email = 'bluenderender@gmail.com';

-- Harus menghasilkan 1 baris: email, auth_id, username 'admin', role 'admin',
-- provider 'email', identity_email 'bluenderender@gmail.com'