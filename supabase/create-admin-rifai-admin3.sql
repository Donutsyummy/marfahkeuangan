-- ============================================
-- LaporanMRFH - Akun ADMIN ke-3: rifai.muh24@gmail.com
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- Target akun yang SUDAH ada di Auth > Users:
--   Email   : rifai.muh24@gmail.com
--   User UID: 744c13e2-ac95-44a8-8db4-d99558e27cbb
-- Script ini TIDAK mengubah password akun tersebut.
-- Yang dilakukan:
--   1. Bersihkan akun duplikat lain yang memakai email sama
--      (sisa akun yang pernah dibuat lewat API).
--   2. Pastikan email terkonfirmasi + identity ada.
--   3. Link public.users jadi role admin (username admin3).
-- Idempoten - aman dijalankan berulang.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ===== 0) Bersihkan akun duplikat ber-email sama dengan UID selain target =====
DELETE FROM public.users
WHERE auth_id IN (
  SELECT id FROM auth.users
  WHERE email = 'rifai.muh24@gmail.com'
    AND id <> '744c13e2-ac95-44a8-8d4b-d995a8e27cbb'::uuid
);

DELETE FROM auth.identities
WHERE user_id IN (
  SELECT id FROM auth.users
  WHERE email = 'rifai.muh24@gmail.com'
    AND id <> '744c13e2-ac95-44a8-8db4-d99558e27cbb'::uuid
);

DELETE FROM auth.users
WHERE email = 'rifai.muh24@gmail.com'
  AND id <> '744c13e2-ac95-44a8-8db4-d99558e27cbb'::uuid;

DO $$
DECLARE
  v_uid uuid := '744c13e2-ac95-44a8-8db4-d99558e27cbb'::uuid;
  v_email text;
BEGIN
  SELECT email INTO v_email FROM auth.users WHERE id = v_uid;

  IF v_email IS NULL THEN
    RAISE EXCEPTION 'auth id % tidak ditemukan di auth.users. Cek UID di Auth > Users.', v_uid;
  END IF;

  -- 1) Pastikan email terkonfirmasi
  UPDATE auth.users
  SET email_confirmed_at = COALESCE(email_confirmed_at, now()),
      raw_user_meta_data  = jsonb_build_object('username', 'admin3'),
      updated_at          = now()
  WHERE id = v_uid;

  -- 2) Pastikan identity email ada (wajib agar signInWithPassword berhasil)
  INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
  VALUES (gen_random_uuid(), v_uid,
          jsonb_build_object('sub', v_uid::text, 'email', v_email, 'email_verified', true),
          'email', v_uid::text, now(), now(), now())
  ON CONFLICT DO NOTHING;

  -- 3) Kalau baris public.users untuk akun ini SUDAH ada -> ubah jadi admin3
  UPDATE public.users
  SET username = 'admin3', name = 'Administrator', role = 'admin', last_seen = now()
  WHERE auth_id = v_uid;

  IF NOT FOUND THEN
    -- 4) Belum ada: kosongkan dulu username 'admin3', lalu insert
    DELETE FROM public.users WHERE username = 'admin3' AND auth_id IS DISTINCT FROM v_uid;

    INSERT INTO public.users (username, name, role, auth_id, last_seen)
    VALUES ('admin3', 'Administrator', 'admin', v_uid, now());
  END IF;

  RAISE NOTICE 'OK: % sekarang admin (username admin3, auth id %)', v_email, v_uid;
END $$;

-- ===== VERIFIKASI =====
SELECT u.email, u.id AS auth_id, u.email_confirmed_at, p.username, p.role, p.name, i.provider
FROM auth.users u
LEFT JOIN public.users p    ON p.auth_id = u.id
LEFT JOIN auth.identities i ON i.user_id = u.id
WHERE u.id = '744c13e2-ac95-44a8-8db4-d99558e27cbb'::uuid
