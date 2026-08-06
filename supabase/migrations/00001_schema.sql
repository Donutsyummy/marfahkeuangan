-- ============================================
-- LaporanMRFH - Supabase Database Schema
-- IDEMPOTENT: aman dijalankan ulang berkali-kali
-- ============================================

-- 1. USERS (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('admin', 'editor', 'viewer')),
  auth_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  last_seen TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ter
-- 2. PENJUALAN (Sales)
CREATE TABLE IF NOT EXISTS public.penjualan (
  id BIGSERIAL PRIMARY KEY,
  tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
  modal BIGINT NOT NULL DEFAULT 0,
  produk TEXT NOT NULL,
  untung_bersih BIGINT NOT NULL DEFAULT 0,
  rugi BIGINT NOT NULL DEFAULT 0,
  evaluasi TEXT DEFAULT '',
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.penjualan ENABLE ROW LEVEL SECURITY;

-- 3. KAS (Cash)
CREATE TABLE IF NOT EXISTS public.kas (
  id BIGSERIAL PRIMARY KEY,
  tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
  keterangan TEXT NOT NULL,
  jumlah BIGINT NOT NULL DEFAULT 0,
  tipe TEXT NOT NULL CHECK (tipe IN ('masuk', 'keluar')),
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.kas ENABLE ROW LEVEL SECURITY;

-- 4. KEBUTUHAN (Needs)
CREATE TABLE IF NOT EXISTS public.kebutuhan (
  id BIGSERIAL PRIMARY KEY,
  tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
  bisnis_perlu TEXT NOT NULL,
  bisnis_untuk TEXT NOT NULL,
  kerjasama_perlu TEXT NOT NULL,
  kerjasama_untuk TEXT NOT NULL,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.kebutuhan ENABLE ROW LEVEL SECURITY;

-- 5. KERJASAMA (Collaborations)
CREATE TABLE IF NOT EXISTS public.kerjasama (
  id BIGSERIAL PRIMARY KEY,
  tanggal DATE NOT NULL DEFAULT CURRENT_DATE,
  untung_produk BIGINT NOT NULL DEFAULT 0,
  bagi_hasil BIGINT NOT NULL DEFAULT 0,
  rugi BIGINT NOT NULL DEFAULT 0,
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.kerjasama ENABLE ROW LEVEL SECURITY;

-- 6. BULANAN (Monthly Reports)
CREATE TABLE IF NOT EXISTS public.bulanan (
  id BIGSERIAL PRIMARY KEY,
  periode TEXT NOT NULL,
  untung_keseluruhan BIGINT NOT NULL DEFAULT 0,
  rugi_keseluruhan BIGINT NOT NULL DEFAULT 0,
  untung_bisnis BIGINT NOT NULL DEFAULT 0,
  rugi_bisnis BIGINT NOT NULL DEFAULT 0,
  untung_kerjasama BIGINT NOT NULL DEFAULT 0,
  rugi_kerjasama BIGINT NOT NULL DEFAULT 0,
  target TEXT DEFAULT '',
  evaluasi TEXT DEFAULT '',
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.bulanan ENABLE ROW LEVEL SECURITY;

-- 7. TAHUNAN (Yearly Reports)
CREATE TABLE IF NOT EXISTS public.tahunan (
  id BIGSERIAL PRIMARY KEY,
  tahun TEXT NOT NULL,
  untung_keseluruhan BIGINT NOT NULL DEFAULT 0,
  rugi_keseluruhan BIGINT NOT NULL DEFAULT 0,
  untung_bisnis BIGINT NOT NULL DEFAULT 0,
  rugi_bisnis BIGINT NOT NULL DEFAULT 0,
  untung_kerjasama BIGINT NOT NULL DEFAULT 0,
  rugi_kerjasama BIGINT NOT NULL DEFAULT 0,
  target TEXT DEFAULT '',
  evaluasi TEXT DEFAULT '',
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.tahunan ENABLE ROW LEVEL SECURITY;

-- 8. CHAT MESSAGES
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id BIGSERIAL PRIMARY KEY,
  text TEXT NOT NULL,
  username TEXT NOT NULL,
  nama TEXT NOT NULL,
  waktu TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- 9. AKTIVITAS (Activity Logs)
CREATE TABLE IF NOT EXISTS public.aktivitas (
  id BIGSERIAL PRIMARY KEY,
  action TEXT NOT NULL,
  kategori TEXT NOT NULL,
  detail TEXT DEFAULT '',
  nama TEXT NOT NULL,
  waktu TIMESTAMPTZ DEFAULT now(),
  created_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
ALTER TABLE public.aktivitas ENABLE ROW LEVEL SECURITY;

-- 10. SETTINGS
CREATE TABLE IF NOT EXISTS public.settings (
  id BIGSERIAL PRIMARY KEY,
  key TEXT UNIQUE NOT NULL,
  value TEXT
);
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- ========== INDEXES ==========
CREATE INDEX IF NOT EXISTS idx_penjualan_tanggal ON public.penjualan(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_kas_tanggal ON public.kas(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_kebutuhan_tanggal ON public.kebutuhan(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_kerjasama_tanggal ON public.kerjasama(tanggal DESC);
CREATE INDEX IF NOT EXISTS idx_bulanan_periode ON public.bulanan(periode);
CREATE INDEX IF NOT EXISTS idx_tahunan_tahun ON public.tahunan(tahun);
CREATE INDEX IF NOT EXISTS idx_chat_messages_waktu ON public.chat_messages(waktu DESC);
CREATE INDEX IF NOT EXISTS idx_aktivitas_waktu ON public.aktivitas(waktu DESC);

-- ========== TRIGGER: updated_at ==========
CREATE OR REPLACE FUNCTION public.trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at_penjualan ON public.penjualan;
CREATE TRIGGER set_updated_at_penjualan BEFORE UPDATE ON public.penjualan FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at_kas ON public.kas;
CREATE TRIGGER set_updated_at_kas BEFORE UPDATE ON public.kas FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at_kebutuhan ON public.kebutuhan;
CREATE TRIGGER set_updated_at_kebutuhan BEFORE UPDATE ON public.kebutuhan FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at_kerjasama ON public.kerjasama;
CREATE TRIGGER set_updated_at_kerjasama BEFORE UPDATE ON public.kerjasama FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at_bulanan ON public.bulanan;
CREATE TRIGGER set_updated_at_bulanan BEFORE UPDATE ON public.bulanan FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();
DROP TRIGGER IF EXISTS set_updated_at_tahunan ON public.tahunan;
CREATE TRIGGER set_updated_at_tahunan BEFORE UPDATE ON public.tahunan FOR EACH ROW EXECUTE FUNCTION public.trigger_set_updated_at();

-- ========== RLS POLICIES ==========
DO $$
BEGIN
  -- Users: readable by all authenticated, only admin can insert/update
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_select_authenticated') THEN
    CREATE POLICY "users_select_authenticated" ON public.users FOR SELECT USING (auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_insert_admin') THEN
    CREATE POLICY "users_insert_admin" ON public.users FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND (SELECT role FROM public.users WHERE auth_id = auth.uid()) = 'admin');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'users_update_admin') THEN
    CREATE POLICY "users_update_admin" ON public.users FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) = 'admin');
  END IF;

  -- Data tables: all authenticated can read, only admin/editor can write
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'penjualan' AND policyname = 'penjualan_select') THEN
    CREATE POLICY "penjualan_select" ON public.penjualan FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "penjualan_insert" ON public.penjualan FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND (SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "penjualan_update" ON public.penjualan FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "penjualan_delete" ON public.penjualan FOR DELETE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'kas' AND policyname = 'kas_select') THEN
    CREATE POLICY "kas_select" ON public.kas FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "kas_insert" ON public.kas FOR INSERT WITH CHECK ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "kas_update" ON public.kas FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "kas_delete" ON public.kas FOR DELETE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'kebutuhan' AND policyname = 'kebutuhan_select') THEN
    CREATE POLICY "kebutuhan_select" ON public.kebutuhan FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "kebutuhan_insert" ON public.kebutuhan FOR INSERT WITH CHECK ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "kebutuhan_update" ON public.kebutuhan FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "kebutuhan_delete" ON public.kebutuhan FOR DELETE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'kerjasama' AND policyname = 'kerjasama_select') THEN
    CREATE POLICY "kerjasama_select" ON public.kerjasama FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "kerjasama_insert" ON public.kerjasama FOR INSERT WITH CHECK ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "kerjasama_update" ON public.kerjasama FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "kerjasama_delete" ON public.kerjasama FOR DELETE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'bulanan' AND policyname = 'bulanan_select') THEN
    CREATE POLICY "bulanan_select" ON public.bulanan FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "bulanan_insert" ON public.bulanan FOR INSERT WITH CHECK ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "bulanan_update" ON public.bulanan FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "bulanan_delete" ON public.bulanan FOR DELETE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tahunan' AND policyname = 'tahunan_select') THEN
    CREATE POLICY "tahunan_select" ON public.tahunan FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "tahunan_insert" ON public.tahunan FOR INSERT WITH CHECK ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "tahunan_update" ON public.tahunan FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
    CREATE POLICY "tahunan_delete" ON public.tahunan FOR DELETE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) IN ('admin', 'editor'));
  END IF;

  -- Chat: all authenticated can read/insert
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'chat_messages' AND policyname = 'chat_select') THEN
    CREATE POLICY "chat_select" ON public.chat_messages FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "chat_insert" ON public.chat_messages FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  END IF;

  -- Aktivitas: all authenticated can read/insert
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'aktivitas' AND policyname = 'aktivitas_select') THEN
    CREATE POLICY "aktivitas_select" ON public.aktivitas FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "aktivitas_insert" ON public.aktivitas FOR INSERT WITH CHECK (auth.role() = 'authenticated');
  END IF;

  -- Settings: all authenticated can read, only admin can write
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'settings' AND policyname = 'settings_select') THEN
    CREATE POLICY "settings_select" ON public.settings FOR SELECT USING (auth.role() = 'authenticated');
    CREATE POLICY "settings_insert" ON public.settings FOR INSERT WITH CHECK ((SELECT role FROM public.users WHERE auth_id = auth.uid()) = 'admin');
    CREATE POLICY "settings_update" ON public.settings FOR UPDATE USING ((SELECT role FROM public.users WHERE auth_id = auth.uid()) = 'admin');
  END IF;
END $$;

-- ========== DEFAULT SETTINGS ==========
INSERT INTO public.settings (key, value) VALUES ('total_uang_manual', NULL) ON CONFLICT (key) DO NOTHING;
