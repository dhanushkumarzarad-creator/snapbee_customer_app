import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables.
/// Never hardcode secrets or environment-specific values anywhere else —
/// everything is read from .env at runtime through this class.
class EnvConfig {
  EnvConfig._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static bool get isProduction => appEnv == 'production';
}
