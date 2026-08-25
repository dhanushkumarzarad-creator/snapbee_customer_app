import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/screens/home/widgets/bottom_navigation_widget.dart';

/// Reproduces the exact shell/navigation pattern used to reach Services from
/// Daily Essentials Home, isolated from Supabase-backed screens: a
/// Daily-Essentials-shaped Scaffold(body: IndexedStack, bottomNavigationBar:
/// BottomNavigationWidget) that pushes a Services-shaped Scaffold of the
/// same shape as a new full-screen route, which then pops back.
class _DailyEssentialsShell extends StatefulWidget {
  const _DailyEssentialsShell();

  @override
  State<_DailyEssentialsShell> createState() => _DailyEssentialsShellState();
}

class _DailyEssentialsShellState extends State<_DailyEssentialsShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const Text('Profile'),
          Builder(
            builder: (context) => ElevatedButton(
              key: const Key('go-to-services'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _ServicesShell()),
              ),
              child: const Text('Go to Services'),
            ),
          ),
          const Text('Category'),
          const Text('Offers'),
          const Text('Orders'),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

class _ServicesShell extends StatefulWidget {
  const _ServicesShell();

  @override
  State<_ServicesShell> createState() => _ServicesShellState();
}

class _ServicesShellState extends State<_ServicesShell> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const Text('Services Profile'),
          Builder(
            builder: (context) => ElevatedButton(
              key: const Key('back-to-daily-essentials'),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Daily Essentials'),
            ),
          ),
          const Text('Services Category'),
          const Text('Services Offers'),
          const Text('Services Orders'),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onTabSelected: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

void main() {
  testWidgets(
    'Daily Essentials bottom nav survives a push-to-Services-then-pop round trip',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _DailyEssentialsShell()),
      );

      expect(find.byType(BottomNavigationWidget), findsOneWidget);

      await tester.tap(find.byKey(const Key('go-to-services')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationWidget), findsOneWidget);
      expect(find.text('Services Category'), findsNothing);

      await tester.tap(find.byKey(const Key('back-to-daily-essentials')));
      await tester.pumpAndSettle();

      expect(
        find.byType(BottomNavigationWidget),
        findsOneWidget,
        reason:
            'Daily Essentials must still own a Scaffold with its bottomNavigationBar after popping back from Services',
      );
      expect(find.text('Go to Services'), findsOneWidget);
    },
  );

  testWidgets(
    'repeated round trips keep restoring the Daily Essentials bottom nav',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: _DailyEssentialsShell()),
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('go-to-services')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('back-to-daily-essentials')));
        await tester.pumpAndSettle();

        expect(
          find.byType(BottomNavigationWidget),
          findsOneWidget,
          reason: 'round trip #$i must restore the bottom nav',
        );
      }
    },
  );
}
