const SUPABASE_URL = 'https://fnquvkfeqxhxfsypkwtn.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZucXV2a2ZlcXhoeGZzeXBrd3RuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODUxMzIxMzMsImV4cCI6MjEwMDcwODEzM30.yDo_Jm47TtjU54Uk1eNt_TAvKtBL9reYii3hBZwALuU';

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
