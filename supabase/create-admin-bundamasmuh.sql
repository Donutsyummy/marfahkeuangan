-- ============================================
-- LaporanMRFH - Buat Akun ADMIN
-- Email: bundamasmuh@gmail.com / Password: bismillah
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- CATATAN:
-- 1. Rebuild bersih akun bundamasmuh@gmail.com (auth.users)
--    + baris public.users (role admin).
-- 2. Data laporan/penjualan TIDAK terdampak.
-- 3. Idempoten - aman dijalankan ulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Hapus akun lama dengan email ini + baris public.users terkait
DELETE FROM public.users
WHERE auth_id IN (SELECT id FROM auth.users WHERE email = 'bundamasmuh@gmail.com');

DELETE FROM auth.users WHERE email = 'bundamasmuh@gmail.com';

-- Hapus kemungkinan baris public.users admin lama tanpa auth (yatim)
DELETE FROM public.users WHERE username = 'admin';

-- Buat ulang akun admin yang bersih
INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data)
VALUES (gen_random_uuid(),
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'bundamasmuh@gmail.com',
    crypt('bismillah', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"username":"admin"}'
);

-- Link public.users admin ke akun yang baru dibuat
INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin', 'Administrator', 'admin', id, now()
FROM auth.users
WHERE email = 'bundamasmuh@gmail.com'
LIMIT 1;
