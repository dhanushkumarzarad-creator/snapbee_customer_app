import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zhdhkvoxkdmsuiyehgsw.supabase.co',
    publishableKey: 'sb_publishable_6CT-UQ0hog6b4Y9oOEljSw_LMH3V3D5',
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
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
