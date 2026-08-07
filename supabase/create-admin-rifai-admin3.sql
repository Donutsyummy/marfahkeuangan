-- ============================================
-- LaporanMRFH - Akun ADMIN ke-3: rifai.muh24@gmail.com
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- PENTING:
--  * Di proyek ini akun rifai.muh24@gmail.com TIDAK kadang ada di
--    auth.users. Script ini KUBUAT apa adanya:
--    - Kalau sudah ada  -> pakai akun itu (password tidak diganti).
--    - Kalau belum ada  -> akun dibuat baru (password: bismillah3).
--  * Semua akun duplikat/junk ber-email sama otomatis dihapus.
--    Script lama yang bikin error "duplicate key users_auth_id_key"
--    TIDAK dipakai lagi.
-- Idempoten - aman dijalankan berulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  v_email text := 'rifai.muh24@gmail.com';
  v_pw     text := 'bismillah3';
  v_uid    uuid;
BEGIN
  -- 1) Cari akun yang benar memakai email ini
  SELECT id INTO v_uid FROM auth.users WHERE email = v_email ORDER BY created_at LIMIT 1;

  -- 2) Kalau belum ada -> buat akun baru yang bersih
  IF v_uid IS NULL THEN
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      confirmation_token, recovery_token, email_change_token_new, email_change_token_current, email_change,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data)
    VALUES (
      gen_random_uuid(),
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      v_email, crypt(v_pw, gen_salt('bf')),
      '', '', '', '', '',
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}',
      '{"username":"admin3"}')
    RETURNING id INTO v_uid;
  END IF;

  -- 3) Bersihkan SEMUA akun lain ber-email sama (junk / duplikat / probe)
  DELETE FROM public.users WHERE auth_id IN (SELECT id FROM auth.users WHERE email = v_email AND id <> v_uid);
  DELETE FROM auth.identities WHERE user_id IN (SELECT id FROM auth.users WHERE email = v_email AND id <> v_uid);
  DELETE FROM auth.users WHERE email = v_email AND id <> v_uid;

  -- 4) Pastikan email terkonfirmasi + metadata username
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, now()),
      raw_user_meta_data  = jsonb_build_object('username', 'admin3'),
      updated_at          = now()
  WHERE id = v_uid;

  -- 5) Pastikan identity email ada (wajib agar signInWithPassword berhasil)
  INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v_uid,
          jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', true),
          'email', v_uid::text, now(), now(), now())
  ON CONFLICT DO NOTHING;

  -- 6) Link public.users sebagai admin ke-3 (username admin3)
  UPDATE public.users
  SET username = 'admin3', name = 'Administrator', role = 'admin', last_seen = now()
  WHERE auth_id = v_uid;

  IF NOT FOUND THEN
    DELETE FROM public.users WHERE username = 'admin3' AND auth_id IS DISTINCT FROM v_uid;
    INSERT INTO public.users (username, name, role, auth_id, last_seen)
    VALUES ('admin3', 'Administrator', 'admin', v_uid, now());
  END IF;

  RAISE NOTICE 'OK: % (% ) sekarang admin (username/email login: %)', v_email, v_uid, v_email;
END $$;

-- ===== VERIFIKASI =====
SELECT u.email, u.id AS auth_id, p.username, p.role, p.name, i.provider
FROM auth.users u
LEFT JOIN public.users p    ON p.auth_id = u.id
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE u.email = 'rifai.muh24@gmail.com';