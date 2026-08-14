const SUPABASE_URL = 'https://fnquvkfeqxhxfsypkwtn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZucXV2a2ZlcXhoeGZzeXBrd3RuIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4NTEzMjEzMywiZXhwIjoyMTAwNzA4MTMzfQ.eoni_UFpRxv27WMW7MlkaY4RACZMKgMKV_p0Yue691w';

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  },
  realtime: {
    params: {
      eventsPerSecond: 10
    }
  }
});
