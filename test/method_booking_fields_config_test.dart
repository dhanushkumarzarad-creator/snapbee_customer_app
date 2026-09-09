import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/booking/method_booking_fields.dart';
import 'package:snapbee_customer_app/features/services/models/service_method.dart';

/// Proves the customer booking form now renders each method's REAL
/// provider configuration (service_vendor_method_configs.method_config +
/// service_allowed_methods.config, surfaced by browse_service_methods),
/// not a hard-coded default. The end-to-end persistence of that config is
/// proven at the DB layer (services_method_readiness_test.sql).
void main() {
  ServiceMethodRow row({
    required String code,
    List<Map<String, dynamic>> schema = const [],
    Map<String, dynamic> serviceConfig = const {},
    Map<String, dynamic> vendorMethodConfig = const {},
  }) =>
      ServiceMethodRow(
        configId: 'c1',
        vendorId: 'v1',
        vendorName: 'Test Provider',
        methodId: 'm1',
        methodCode: code,
        methodName: code,
        methodShortName: code,
        configSchema: schema,
        serviceConfig: serviceConfig,
        vendorMethodConfig: vendorMethodConfig,
      );

  Future<Map<String, dynamic>> pump(WidgetTester tester, ServiceMethodRow m) async {
    var latest = <String, dynamic>{};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MethodBookingFields(method: m, onChanged: (v) => latest = v),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    return latest;
  }

  testWidgets('subscription uses the vendor\'s configured frequency, not the default', (tester) async {
    final m = row(
      code: 'subscription',
      schema: const [
        {
          'key': 'frequency',
          'type': 'select',
          'options': ['weekly', 'fortnightly', 'monthly', 'quarterly'],
        },
      ],
      vendorMethodConfig: const {'frequency': 'quarterly', 'visits_included': 2},
    );
    final values = await pump(tester, m);
    expect(values['plan_frequency'], 'quarterly');
    expect(find.textContaining('Includes 2 visit(s)'), findsOneWidget);
  });

  testWidgets('hybrid offers only the component methods the provider configured', (tester) async {
    final m = row(
      code: 'hybrid',
      vendorMethodConfig: const {
        'component_methods': ['appointment_booking', 'home_visit', 'pickup_and_drop'],
      },
    );
    await pump(tester, m);
    await tester.tap(find.text('Which part happens first? *'));
    await tester.pumpAndSettle();
    expect(find.text('pickup_and_drop').hitTestable(), findsOneWidget);
    expect(find.text('store_delivery'), findsNothing);
  });

  testWidgets('multi-step workflow shows the provider\'s configured stages', (tester) async {
    final m = row(
      code: 'multi_step_workflow',
      vendorMethodConfig: const {
        'steps': ['Site survey', 'Fixed quote', 'Execution'],
      },
    );
    await pump(tester, m);
    expect(find.text('1. Site survey'), findsOneWidget);
    expect(find.text('2. Fixed quote'), findsOneWidget);
    expect(find.text('3. Execution'), findsOneWidget);
    // the generic default set must NOT appear
    expect(find.text('1. Inspection'), findsNothing);
  });

  testWidgets('store pickup shows the provider\'s branch as the hint', (tester) async {
    final m = row(
      code: 'store_pickup',
      vendorMethodConfig: const {'pickup_branch': 'Jayanagar outlet'},
    );
    await pump(tester, m);
    expect(find.text('Jayanagar outlet'), findsOneWidget);
  });

  testWidgets('walk-in surfaces the provider\'s queue-token support', (tester) async {
    final m = row(code: 'walk_in', vendorMethodConfig: const {'queue_support': true});
    await pump(tester, m);
    expect(find.textContaining('queue token on arrival'), findsOneWidget);
  });

  testWidgets('pickup & drop asks for a distinct drop-off address', (tester) async {
    final m = row(code: 'pickup_and_drop');
    await pump(tester, m);
    expect(find.text('Drop-off address *'), findsOneWidget);
  });
}
