class SupabaseConfig {
  // 🛡️ SECURITY NOTE: Do not hardcode sensitive keys here.
  // Use --dart-define or --dart-define-from-file to provide these at build time.
  // Example: flutter run --dart-define=SUPABASE_URL=your_url ...

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String serviceRoleKey = String.fromEnvironment(
    'SUPABASE_SERVICE_ROLE_KEY',
  );
}
