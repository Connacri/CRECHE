// lib/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Version qui supporte à la fois .env et --dart-define
  static String get supabaseUrl {
    // Priorité au --dart-define (utilisé par CI/CD)
    final dartDefine = const String.fromEnvironment('SUPABASE_URL');
    if (dartDefine.isNotEmpty) return dartDefine;

    // Fallback sur .env (développement local)
    return dotenv.env['SUPABASE_URL'] ?? '';
  }

  static String get supabaseAnonKey {
    final dartDefine = const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    return dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  static String get supabaseServiceRoleKey {
    final dartDefine = const String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY');
    if (dartDefine.isNotEmpty) return dartDefine;
    return dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? '';
  }
}