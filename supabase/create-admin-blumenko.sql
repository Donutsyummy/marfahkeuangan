-- ============================================
-- LaporanMRFH - Buat Akun ADMIN
-- Email: bluenderender@gmail.com / Password: faiqbaik
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- Catatan: email yang dipakai = bluenderender@gmail.com (bukan yang bermasalah)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Hapus email ini KALAU duplikat (aman dijalankan ulang)
DELETE FROM public.users
WHERE auth_id IN (SELECT id FROM auth.users WHERE email = 'bluenderender@gmail.com');
DELETE FROM auth.users WHERE email = 'bluenderender@gmail.com';

-- Buat akun auth baru yang bersih
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
VALUES (gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'bluenderender@gmail.com',
    crypt('faiqbaik', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"username":"admin"}'
);

-- Link public.users (role admin) ke akun yang baru dibuat
INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin', 'Administrator', 'admin', id, now()
FROM auth.users
WHERE email = 'bluenderender@gmail.com'
LIMIT 1;