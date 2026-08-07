-- ============================================
-- LaporanMRFH - Buat Akun Login
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- CATATAN:
--  1. Aplikasi login memakai format email: username@laporanmrfh.local
--     (lihat js/app.js -> signInWithPassword(username + '@laporanmrfh.local'))
--  2. Ganti password sebelum menjalankan (bagian crypt('...', gen_salt('bf'))).
--  3. Role yang tersedia:
--     - admin  : bisa tambah/edit/hapus semua data
--     - editor : bisa tambah/edit/hapus semua data
--     - viewer : hanya bisa melihat (tanpa form input)
--  4. Jika error "function crypt does not exist", jalankan dulu:
--     CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============= AKUN ADMIN =============
DO $$
DECLARE
  v_uid_admin uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data
  ) VALUES (
    v_uid_admin,
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'admin@laporanmrfh.local',
    crypt('admin', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"username":"admin"}'
  );

  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('admin', 'Administrator', 'admin', v_uid_admin, now());
END $$;

-- ============= AKUN VIEWER (hanya lihat) ===========
DO $$
DECLARE
  v_uid_viewer uuid := gen_random_uuid();
BEGIN
  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data
  ) VALUES (
    v_uid_viewer,
    '00000000-0000-0000-0000-000000000000',
    'authenticated', 'authenticated',
    'viewer@laporanmrfh.local',
    crypt('viewer', gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}',
    '{"username":"viewer"}'
  );

  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('viewer', 'Pengamat', 'viewer', v_uid_viewer, now());
END $$;