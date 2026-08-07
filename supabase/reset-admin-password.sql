-- ============================================
-- LaporanMRFH - Reset/SET ulang password admin
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- 1. Aplikasi set login email admin@laporanmrfh.local (js/app.js:65)
-- 2. Set password baru di bawah menjadi yang kamu inginkan
-- 3. Setelah restore, login pakai username "admin" + password baru

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    CREATE EXTENSION IF NOT EXISTS pgcrypto;
  END IF;
END $$;

UPDATE auth.users
SET encrypted_password = crypt('admin', gen_salt('bf')),
    updated_at = now()
WHERE email = 'admin@laporanmrfh.local';