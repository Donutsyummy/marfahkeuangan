-- ============================================
-- LaporanMRFH - Perbaiki & Siapkan Akun Login
-- Versi idempoten: aman dijalankan berkali-kali
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- HASIL AKHIR:
--   admin  : email admin@laporanmrfh.local   password: admin   role: admin
--   viewer : email viewer@laporanmrfh.local  password: viewer  role: viewer
-- Script ini TIDAK membuat duplikat (pakai ON CONFLICT).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ========= AKUN ADMIN =========
DO $$
DECLARE v_auth uuid;
BEGIN
  SELECT id INTO v_auth FROM auth.users WHERE email = 'admin@laporanmrfh.local' ORDER BY id LIMIT 1;

  -- kalau email belum ada di auth.users, buat
  IF v_auth IS NULL THEN
    v_auth := gen_random_uuid();
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
    VALUES (v_auth, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'admin@laporanmrfh.local', crypt('admin', gen_salt('bf')), now(), now(), now(),
            '{"provider":"email","providers":["email"]}', '{"username":"admin"}');
  END IF;

  -- pastikan password jadi 'admin'
  UPDATE auth.users SET encrypted_password = crypt('admin', gen_salt('bf')), updated_at = now() WHERE id = v_auth;

  -- link public.users (admin) ke auth_id yang benar + isi username yg sudah ada
  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('admin', 'Administrator', 'admin', v_auth, now())
  ON CONFLICT (username) DO UPDATE SET auth_id = EXCLUDED.auth_id, role = EXCLUDED.role;
END $$;

-- ========= AKUN VIEWER =========
DO $$
DECLARE v_auth uuid;
BEGIN
  SELECT id INTO v_auth FROM auth.users WHERE email = 'viewer@laporanmrfh.local' ORDER BY id LIMIT 1;

  IF v_auth IS NULL THEN
    v_auth := gen_random_uuid();
    INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, aud, role, raw_app_meta_data, raw_user_meta_data, instance_id)
    VALUES (v_auth, 'viewer@laporanmrfh.local', crypt('viewer', gen_salt('bf')), now(), now(), now(),
            'authenticated', 'authenticated', '{"provider":"email","providers":["email"]}', '{"username":"viewer"}',
            '00000000-0000-0000-0000-000000000000');
  END IF;

  UPDATE auth.users SET encrypted_password = crypt('viewer', gen_salt('bf')), updated_at = now() WHERE id = v_auth;

  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('viewer', 'Pengamat', 'viewer', v_auth, now())
  ON CONFLICT (username) DO UPDATE SET auth_id = EXCLUDED.auth_id, role = EXCLUDED.role;
END $$;