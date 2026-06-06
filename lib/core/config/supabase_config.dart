class SupabaseConfig {
  static const String _defaultUrl = 'https://ftaqbokfeahvfndorzuf.supabase.co';
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0YXFib2tmZWFodmZuZG9yenVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ3NDE5MDEsImV4cCI6MjA4MDMxNzkwMX0.I_pvSiN5S8Y31XS3NV2Gw5dVrCDNjXqmUUSloycXhcw';
  
  // 🛡️ Clé Service Role pour les opérations administratives (Bypass RLS)
  static const String _defaultServiceRoleKey = 
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ0YXFib2tmZWFodmZuZG9yenVmIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDc0MTkwMSwiZXhwIjoyMDgwMzE3OTAxfQ.WLyMj_uZK9cvDStnpXzsttBf6EBi4cr5dU6tEaznNWo';

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultAnonKey,
  );

  static const String serviceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
    defaultValue: _defaultServiceRoleKey,
  );
}
