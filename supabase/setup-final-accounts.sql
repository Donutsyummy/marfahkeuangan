-- ============================================
-- LaporanMRFH - Akun Final
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- HASIL:
--   Admin  : bluenderende@gmail.com / faiqbaik  (role: admin)
--   Viewer : javasmeme@gmail.com    / faiqbaik  (role: viewer)
-- Idempoten: aman dijalankan berkali-kali (tidak membuat duplikat).
-- Aplikasi sekarang menerima email penuh (js/app.js).

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------- ADMIN: bluenderende@gmail.com ----------
DO $$
DECLARE v_auth uuid;
BEGIN
  SELECT id INTO v_auth FROM auth.users WHERE email = 'bluenderende@gmail.com' ORDER BY id LIMIT 1;

  IF v_auth IS NULL THEN
    v_auth := gen_random_uuid();
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
    VALUES (v_auth, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'bluenderende@gmail.com', crypt('faiqbaik', gen_salt('bf')), now(), now(), now(),
            '{"provider":"email","providers":["email"]}', '{"username":"admin"}');
  END IF;

  UPDATE auth.users SET encrypted_password = crypt('faiqbaik', gen_salt('bf')), updated_at = now() WHERE id = v_auth;

  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('admin', 'Administrator', 'admin', v_auth, now())
  ON CONFLICT (username) DO UPDATE SET auth_id = EXCLUDED.auth_id, role = EXCLUDED.role;
END $$;

-- ---------- VIEWER: javasmeme@gmail.com ----------
DO $$
DECLARE v_auth uuid;
BEGIN
  SELECT id INTO v_auth FROM auth.users WHERE email = 'javasmeme@gmail.com' ORDER BY id LIMIT 1;

  IF v_auth IS NULL THEN
    v_auth := gen_random_uuid();
    INSERT INTO auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
    VALUES (v_auth, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
            'javasmeme@gmail.com', crypt('faiqbaik', gen_salt('bf')), now(), now(), now(),
            '{"provider":"email","providers":["email"]}', '{"username":"viewer"}');
  END IF;

  UPDATE auth.users SET encrypted_password = crypt('faiqbaik', gen_salt('bf')), updated_at = now() WHERE id = v_auth;

  INSERT INTO public.users (username, name, role, auth_id, last_seen)
  VALUES ('viewer', 'Pengamat', 'viewer', v_auth, now())
  ON CONFLICT (username) DO UPDATE SET auth_id = EXCLUDED.auth_id, role = EXCLUDED.role;
END $$;