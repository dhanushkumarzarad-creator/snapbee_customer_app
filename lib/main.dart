import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env_config.dart';
import 'core/constants/app_colors.dart';
import 'core/design/snapbee_design.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    publishableKey: EnvConfig.supabaseAnonKey,
    // APP_ENV was previously read into EnvConfig.appEnv/isProduction but never
    // consumed anywhere (dead getters) - the SDK own verbose debug logging
    // otherwise defaults to kDebugMode (a build-mode flag, not our env
    // config) and would stay noisy if a production-configured .env is ever
    // run outside a release build (e.g. flutter run against production).
    debug: !EnvConfig.isProduction,
  );

  runApp(const SnapBeeApp());
}

class SnapBeeApp extends StatelessWidget {
  const SnapBeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryOrange,
      primary: AppColors.primaryOrange,
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SnapBee',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: SnapBeeColors.scaffold,
        // System font; the reference hierarchy is achieved via weights/sizes
        // in SnapBeeText rather than a bundled typeface.
        textTheme: Typography.blackMountainView.apply(
          bodyColor: SnapBeeColors.ink,
          displayColor: SnapBeeColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: SnapBeeColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: SnapBeeColors.ink,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: SnapBeeColors.hairline,
          thickness: 1,
          space: 1,
        ),
        cardTheme: CardThemeData(
          color: SnapBeeColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: SnapBeeColors.chipFill,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnapBeeSpacing.rChip),
          ),
          labelStyle: SnapBeeText.label,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryOrange,
            side: BorderSide(color: AppColors.primaryOrange.withValues(alpha: 0.5)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SnapBeeColors.navy,
          contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

/// LoginScreen already exists fully-implemented (real
/// `Supabase.auth.signInWithPassword`) but was never reached from app
/// boot — `main.dart` went straight to `MainScreen` regardless of session
/// state. This is the minimal fix: show LoginScreen when signed out,
/// MainScreen when signed in, and keep listening so a sign-out (from
/// Profile, once that's wired) drops back to LoginScreen automatically.
/// Everything else about MainScreen/bottom nav/Profile is untouched, per
/// this task's own "keep the current Bottom Navigation model unchanged"
/// instruction.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, Supabase.instance.client.auth.currentSession),
      builder: (context, snapshot) {
        final signedIn = snapshot.data?.session != null;
        return signedIn ? const MainScreen() : const LoginScreen();
      },
    );
  }
}
