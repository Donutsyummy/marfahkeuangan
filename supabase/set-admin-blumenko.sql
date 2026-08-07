-- ============================================
-- LaporanMRFH - Jadikan bluenderender@gmail.com sebagai ADMIN
-- Email: bluenderender@gmail.com (akun sudah dibuat via Supabase Auth)
-- Jalankan di Supabase Dashboard > SQL Editor
-- ============================================
-- Upsert akun ke public.users sebagai admin
INSERT INTO public.users (username, name, role, auth_id, last_seen)
SELECT 'admin', 'Administrator', 'admin', id, now()
FROM auth.users
WHERE email = 'bluenderender@gmail.com'
LIMIT 1
ON CONFLICT (auth_id) DO UPDATE SET
  role = 'admin',
  name = 'Administrator',
  updated_at = now();

-- Pastikan tidak ada konflik username 'admin' duplikat (kunci unique username)
DELETE FROM public.users
WHERE username = 'admin'
  AND auth_id IS DISTINCT FROM (SELECT id FROM auth.users WHERE email = 'bluenderender@gmail.com' LIMIT 1);