-- ============================================
-- LaporanMRFH - FIX 500 "Database error querying schema"
-- Penyebab: kolom token di auth.users berisi NULL
-- (ketika user dibuat manual via INSERT SQL, GoTrue
--  tidak bisa membaca NULL sebagai string).
-- Jadikan bundamasmuh@gmail.com sebagai ADMIN.
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- Idempoten - aman dijalankan ulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===== 1) FIX UTAMA: ubah kolom NULL -> string kosong =====
UPDATE auth.users
SET
  confirmation_token        = COALESCE(confirmation_token, ''),
  recovery_token            = COALESCE(recovery_token, ''),
  email_change_token_new    = COALESCE(email_change_token_new, ''),
  email_change_token_current= COALESCE(email_change_token_current, ''),
  email_change              = COALESCE(email_change, '');

-- ===== 2) Pastikan identity email ada (WAJIB) =====
INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
SELECT gen_random_uuid(), id,
    jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true),
    'email', id::text, now(), now(), now()
FROM auth.users
WHERE email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com')
ON CONFLICT DO NOTHING;

-- ===== 3) Jadikan bundamasmuh@gmail.com ADMIN di public.users =====
DELETE FROM public.users WHERE username = 'admin'; -- hapus admin lama (jika ada)

INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin', 'Administrator', 'admin', id, now()
FROM auth.users
WHERE email = 'bundamasmuh@gmail.com'
ON CONFLICT (username) DO UPDATE
SET role = EXCLUDED.role, name = EXCLUDED.name, auth_id = EXCLUDED.auth_id, last_seen = EXCLUDED.last_seen;

-- ===== 4) Verifikasi: harus tampil role=admin, provider=email, token terisi =====
SELECT u.email,
       p.username, p.role, p.name,
       i.provider,
       (u.confirmation_token IS NOT NULL) AS confirmation_ok,
       (u.recovery_token IS NOT NULL)     AS recovery_ok,
       (u.email_change IS NOT NULL)       AS email_change_ok
FROM auth.users u
LEFT JOIN public.users p    ON p.auth_id = u.id
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE u.email IN ('bundamasmuh@gmail.com', 'bluenderender@gmail.com');