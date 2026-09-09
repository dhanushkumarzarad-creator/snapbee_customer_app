// Categories screen building blocks — reference 02_Categories.png.
//   * CategoryRow.fromJson maps the new vertical / display_order /
//     visibility columns (category_vertical_images.sql).
//   * resolveMainForChip resolves the FOOD/GROCERY/MEAT chips to a real
//     Daily Essentials main category by name (never an unrelated one).
//   * CategorySelector renders the exact 8-chip structure and reports taps.
//   * CategoryGridCard renders the name + arrow and falls back to an icon
//     when the Admin has not uploaded an image.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snapbee_customer_app/data/repositories/category_repository.dart';
import 'package:snapbee_customer_app/screens/category/widgets/category_grid_card.dart';
import 'package:snapbee_customer_app/screens/category/widgets/category_selector.dart';

CategoryRow _row(String name, {String? parent, String? vertical}) => CategoryRow(
      id: name,
      name: name,
      status: 'active',
      parentCategoryId: parent,
      vertical: vertical,
    );

void main() {
  group('CategoryRow.fromJson', () {
    test('maps vertical / display_order / visibility', () {
      final r = CategoryRow.fromJson({
        'id': 'c1',
        'name': 'Grocery',
        'description': 'Everyday staples',
        'status': 'active',
        'image_url': 'https://cdn.example/grocery.png',
        'parent_category_id': null,
        'vertical': 'daily_essentials',
        'display_order': 3,
        'visibility': true,
      });
      expect(r.name, 'Grocery');
      expect(r.vertical, 'daily_essentials');
      expect(r.displayOrder, 3);
      expect(r.visibility, isTrue);
      expect(r.isMain, isTrue);
    });

    test('tolerates the pre-migration row shape (no new columns)', () {
      final r = CategoryRow.fromJson({
        'id': 'c2',
        'name': 'Bakery',
        'description': '',
        'status': 'active',
        'parent_category_id': 'c1',
      });
      expect(r.vertical, isNull);
      expect(r.displayOrder, isNull);
      expect(r.visibility, isTrue);
      expect(r.isMain, isFalse);
    });
  });

  group('resolveMainForChip', () {
    final mains = [
      _row('Bakery'),
      _row('Restaurants'),
      _row('Grocery'),
      _row('Fresh Meat'),
      _row('Electronics'),
    ];

    test('FOOD resolves to Restaurants (alias)', () {
      expect(resolveMainForChip(mains, 'food')?.name, 'Restaurants');
    });
    test('GROCERY resolves to Grocery (exact)', () {
      expect(resolveMainForChip(mains, 'grocery')?.name, 'Grocery');
    });
    test('MEAT resolves to Fresh Meat (alias)', () {
      expect(resolveMainForChip(mains, 'meat')?.name, 'Fresh Meat');
    });
    test('prefers an exact "Food" over the Restaurants alias', () {
      final withFood = [..._exact(), _row('Food')];
      expect(resolveMainForChip(withFood, 'food')?.name, 'Food');
    });
    test('returns null when nothing matches', () {
      expect(resolveMainForChip([_row('Electronics')], 'meat'), isNull);
    });
  });

  group('CategorySelector', () {
    testWidgets('renders the exact 8 chips in order and reports taps',
        (tester) async {
      const expected = [
        'All', 'Food', 'Grocery', 'Meat',
        'Services', 'Travel', 'Entertainment', 'E-Commerce',
      ];
      expect(kCategoryChips.map((c) => c.label).toList(), expected);

      CategoryChipSpec? tapped;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CategorySelector(
            selectedKey: 'all',
            onSelected: (c) => tapped = c,
          ),
        ),
      ));
      for (final label in expected) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Services'));
      expect(tapped?.key, 'services');
      expect(tapped?.vertical, 'services');
    });
  });

  group('CategoryGridCard', () {
    testWidgets('shows the name + arrow and an icon when no image is set',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 200,
            child: CategoryGridCard(
              category: _row('Fresh Meat'),
              tintIndex: 0,
            ),
          ),
        ),
      ));
      expect(find.text('Fresh Meat'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      // no network image widget when image_url is empty
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('tap fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 200,
            child: CategoryGridCard(
              category: _row('Grocery'),
              tintIndex: 1,
              onTap: () => taps++,
            ),
          ),
        ),
      ));
      await tester.tap(find.text('Grocery'));
      expect(taps, 1);
    });
  });
}

List<CategoryRow> _exact() => [
      _row('Bakery'),
      _row('Restaurants'),
      _row('Grocery'),
    ];
