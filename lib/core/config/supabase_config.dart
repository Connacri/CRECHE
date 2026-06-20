import 'package:flutter_dotenv/flutter_dotenv.dart';

// class SupabaseConfig {
//   static const String _defaultUrl = 'https://tlvrlyivgrbltuinqehu.supabase.co';
//   static const String _defaultAnonKey =
//       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRsdnJseWl2Z3JibHR1aW5xZWh1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyNTIzMTgsImV4cCI6MjA5NTgyODMxOH0.8ru-nT6Zl1c6TPiUnchtVJsWGYouJaj5kt7jkWr7xY8';
//
//   // 🛡️ Clé Service Role pour les opérations administratives (Bypass RLS)
//   static const String _defaultServiceRoleKey =
//       'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRsdnJseWl2Z3JibHR1aW5xZWh1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDI1MjMxOCwiZXhwIjoyMDk1ODI4MzE4fQ.WLyMj_uZK9cvDStnpXzsttBf6EBi4cr5dU6tEaznNWo';
//
//   static const String url = String.fromEnvironment(
//     'SUPABASE_URL',
//     defaultValue: _defaultUrl,
//   );
//
//   static const String anonKey = String.fromEnvironment(
//     'SUPABASE_ANON_KEY',
//     defaultValue: _defaultAnonKey,
//   );
//
//   static const String serviceRoleKey = String.fromEnvironment(
//     'SUPABASE_SERVICE_ROLE_KEY',
//     defaultValue: _defaultServiceRoleKey,
//   );
// }

class SupabaseConfig {
  static String get url {
    const fromEnv = String.fromEnvironment('SUPABASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get anonKey {
    const fromEnv = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static String get serviceRoleKey {
    const fromEnv = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    return dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  }
}