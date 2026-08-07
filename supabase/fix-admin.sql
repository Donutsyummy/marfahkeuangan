-- ============================================
-- LaporanMRFH - Perbaiki akun ADMIN (bluenderende@gmail.com)
-- Menghapus akun auth rusak + rebuild bersih
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- CATATAN:
-- 1. Ini MENGHAPUS & membuat ulang user bluenderende@gmail.com di
--    auth.users serta row public.users (role admin).
-- 2. Data laporan/penjualan TIDAK terdampak (created_by akan null utk entri lama).
-- 3. Idempoten - aman dijalankan ulang.

DO $$
DECLARE v_old uuid;
DECLARE v_new uuid := gen_random_uuid();
BEGIN
  -- Hapus akun auth lama (kalau ada) + row public.users terkait
  SELECT id INTO v_old FROM auth.users WHERE email = 'bluenderende@gmail.com' ORDER BY id LIMIT 1;
  IF v_old IS NOT NULL THEN
    DELETE FROM public.users WHERE auth_id = v_old AND username <> 'admin' OR auth_id = v_old;
    DELETE FROM auth.users WHERE id = v_old;
  END IF;

  -- Buat ulang akun admin yang bersih
  INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data)
  VALUES (v_new,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'bluenderende@gmail.com',
      crypt('faiqbaik', gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"username":"admin"}');

  -- Pastikan user admin di public.users ter-link
  DELETE FROM public.users WHERE username = 'admin';
  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('admin', 'Administrator', 'admin', v_new, now());
END $$;