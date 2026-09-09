import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables.
/// Never hardcode secrets or environment-specific values anywhere else —
/// everything is read from .env at runtime through this class.
class EnvConfig {
  EnvConfig._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  /// Razorpay PUBLISHABLE key id — safe to ship in the client. Empty until
  /// configured; PaymentRepository.isOnlinePaymentAvailable stays false and
  /// checkout keeps Cash on Delivery as the working path. The SECRET
  /// (RAZORPAY_KEY_SECRET) and RAZORPAY_WEBHOOK_SECRET are NEVER read here —
  /// they live only in the Supabase Edge Function environment.
  ///
  /// Guarded so it is safe to read in unit tests where `.env` was never
  /// loaded (dotenv.env throws until `dotenv.load()` runs).
  static String get razorpayKeyId {
    try {
      return dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static bool get isProduction => appEnv == 'production';
}
