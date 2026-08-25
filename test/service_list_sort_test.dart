import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/features/services/categories/service_list_screen.dart';
import 'package:snapbee_customer_app/features/services/models/service.dart';

ServiceRow _service({
  required String id,
  required String name,
  String description = '',
  required double price,
  required int duration,
}) =>
    ServiceRow(
      id: id,
      categoryId: 'cat-1',
      name: name,
      description: description,
      basePrice: price,
      durationMinutes: duration,
    );

void main() {
  final services = [
    _service(id: '1', name: 'AC Gas Refill', description: 'Top up refrigerant', price: 999, duration: 45),
    _service(id: '2', name: 'AC Deep Clean', description: 'Full unit teardown clean', price: 599, duration: 90),
    _service(id: '3', name: 'AC Installation', description: 'New split AC mounting', price: 1499, duration: 120),
  ];

  group('filterAndSortServices', () {
    test('relevance (no sort) preserves original order', () {
      final result = filterAndSortServices(services, query: '', sort: ServiceSort.relevance);
      expect(result.map((s) => s.id), ['1', '2', '3']);
    });

    test('priceLowHigh sorts ascending by basePrice', () {
      final result = filterAndSortServices(services, query: '', sort: ServiceSort.priceLowHigh);
      expect(result.map((s) => s.id), ['2', '1', '3']);
    });

    test('priceHighLow sorts descending by basePrice', () {
      final result = filterAndSortServices(services, query: '', sort: ServiceSort.priceHighLow);
      expect(result.map((s) => s.id), ['3', '1', '2']);
    });

    test('durationShort sorts ascending by durationMinutes', () {
      final result = filterAndSortServices(services, query: '', sort: ServiceSort.durationShort);
      expect(result.map((s) => s.id), ['1', '2', '3']);
    });

    test('nameAZ sorts alphabetically, case-insensitive', () {
      final result = filterAndSortServices(services, query: '', sort: ServiceSort.nameAZ);
      expect(result.map((s) => s.id), ['2', '1', '3']);
    });

    test('query filters by name, case-insensitive', () {
      final result = filterAndSortServices(services, query: 'install', sort: ServiceSort.relevance);
      expect(result.map((s) => s.id), ['3']);
    });

    test('query also matches the description', () {
      final result = filterAndSortServices(services, query: 'refrigerant', sort: ServiceSort.relevance);
      expect(result.map((s) => s.id), ['1']);
    });

    test('query with no matches returns an empty list, not the unfiltered list', () {
      final result = filterAndSortServices(services, query: 'plumbing', sort: ServiceSort.relevance);
      expect(result, isEmpty);
    });

    test('filter and sort combine: matches narrowed first, then sorted', () {
      final result = filterAndSortServices(services, query: 'ac', sort: ServiceSort.priceLowHigh);
      expect(result.map((s) => s.id), ['2', '1', '3']);
    });
  });
}
