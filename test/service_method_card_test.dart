// Widget coverage for ServiceMethodCard — the customer-facing method card.
//   * an AVAILABLE method: tappable, shows name / price / duration, fires
//     onBook;
//   * a CURRENTLY-UNAVAILABLE method: shown (not hidden) with a
//     customer-safe "Currently Unavailable" reason, NOT tappable;
//   * no internal AI / QC / admin / risk / status wording is ever rendered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/categories/widgets/service_method_card.dart';
import 'package:snapbee_customer_app/features/services/models/service_method.dart';

ServiceMethodRow _method({
  bool available = true,
  MethodUnavailableReason? reason,
  double? price = 250,
  int? duration = 45,
}) =>
    ServiceMethodRow(
      configId: 'cfg-1',
      vendorId: 'v-1',
      vendorName: 'Acme Services',
      serviceId: 'svc-1',
      serviceName: 'AC Deep Clean',
      methodId: 'm-1',
      methodCode: 'home_visit',
      methodName: 'Home Visit',
      methodShortName: 'Home Visit',
      definition: 'A technician comes to your home.',
      price: price,
      durationMinutes: duration,
      isAvailable: available,
      unavailableReason: available ? null : (reason ?? MethodUnavailableReason.capacityFull),
    );

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  testWidgets('available method: renders name/price/duration and is tappable', (tester) async {
    var booked = 0;
    await _pump(tester, ServiceMethodCard(method: _method(), onBook: () => booked++));

    expect(find.text('Home Visit'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.textContaining('₹250'), findsOneWidget);
    expect(find.textContaining('45 min'), findsOneWidget);

    await tester.tap(find.byType(InkWell).first);
    expect(booked, 1);
  });

  testWidgets('currently-unavailable method: shown with reason, not tappable', (tester) async {
    var booked = 0;
    await _pump(
      tester,
      ServiceMethodCard(
        method: _method(available: false, reason: MethodUnavailableReason.outsideHours),
        onBook: () => booked++, // card must ignore this when unavailable
      ),
    );

    expect(find.text('Home Visit'), findsOneWidget);
    expect(find.text('Outside booking hours'), findsOneWidget);
    expect(find.text('Available'), findsNothing);

    await tester.tap(find.byType(InkWell).first, warnIfMissed: false);
    await tester.pump();
    expect(booked, 0);
  });

  testWidgets('no internal terminology is rendered', (tester) async {
    for (final r in MethodUnavailableReason.values) {
      await _pump(tester, ServiceMethodCard(method: _method(available: false, reason: r)));
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => (t.data ?? '').toLowerCase());
      final joined = texts.join(' | ');
      for (final banned in const [
        'qc', 'admin', 'ai_', 'risk', 'superseded', 'draft', 'restricted',
        'changes_requested', 'emergency_disabled', 'config', 'status',
      ]) {
        expect(joined.contains(banned), isFalse, reason: 'reason=$r leaked "$banned" in: $joined');
      }
    }
  });
}
