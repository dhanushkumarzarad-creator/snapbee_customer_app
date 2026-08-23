import 'category_models.dart';

/// Temporary in-memory data source.
///
/// Swap this out for a `CategoriesRepository` backed by Supabase later —
/// the screen only depends on `List<CategoryModel>`, so nothing above it
/// needs to change when the real data source lands.
class MockCategoriesData {
  static List<CategoryModel> get categories => [
        CategoryModel(
          id: 'food',
          name: 'Food',
          emoji: '🍔',
          imageUrl:
              'https://images.unsplash.com/photo-1550547660-d9450f859349?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'f1',
              name: 'Chicken Biryani',
              imageUrl:
                  'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=300',
              price: 180,
              mrp: 220,
              rating: 4.5,
              unit: '1 plate',
            ),
            FeaturedProductModel(
              id: 'f2',
              name: 'Chicken Parotta',
              imageUrl:
                  'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300',
              price: 120,
              mrp: 150,
              rating: 4.3,
              unit: '2 pcs',
            ),
            FeaturedProductModel(
              id: 'f3',
              name: 'Veg Meals',
              imageUrl:
                  'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=300',
              price: 90,
              rating: 4.1,
              unit: '1 plate',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'sc1',
              name: 'Cafe',
              imageUrl:
                  'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=300',
            ),
            SubCategoryModel(
              id: 'sc2',
              name: 'Foods',
              imageUrl:
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
            ),
            SubCategoryModel(
              id: 'sc3',
              name: 'Meals',
              imageUrl:
                  'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=300',
            ),
            SubCategoryModel(
              id: 'sc4',
              name: 'Biriyani',
              imageUrl:
                  'https://images.unsplash.com/photo-1589302168068-964664d93dc0?w=300',
            ),
            SubCategoryModel(
              id: 'sc5',
              name: 'Parotta',
              imageUrl:
                  'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'grocery',
          name: 'Grocery',
          emoji: '🛒',
          imageUrl:
              'https://images.unsplash.com/photo-1542838132-92c53300491e?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'g1',
              name: 'Basmati Rice',
              imageUrl:
                  'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300',
              price: 320,
              mrp: 380,
              rating: 4.6,
              unit: '5 kg',
            ),
            FeaturedProductModel(
              id: 'g2',
              name: 'Sunflower Oil',
              imageUrl:
                  'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300',
              price: 145,
              mrp: 165,
              rating: 4.4,
              unit: '1 L',
            ),
            FeaturedProductModel(
              id: 'g3',
              name: 'Toor Dal',
              imageUrl:
                  'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=300',
              price: 165,
              rating: 4.2,
              unit: '1 kg',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'gsc1',
              name: 'Rice',
              imageUrl:
                  'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300',
            ),
            SubCategoryModel(
              id: 'gsc2',
              name: 'Oil',
              imageUrl:
                  'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=300',
            ),
            SubCategoryModel(
              id: 'gsc3',
              name: 'Vegetables',
              imageUrl:
                  'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300',
            ),
            SubCategoryModel(
              id: 'gsc4',
              name: 'Fruits',
              imageUrl:
                  'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=300',
            ),
            SubCategoryModel(
              id: 'gsc5',
              name: 'Snacks',
              imageUrl:
                  'https://images.unsplash.com/photo-1600952841320-db92ec4047ca?w=300',
            ),
            SubCategoryModel(
              id: 'gsc6',
              name: 'Beverages',
              imageUrl:
                  'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=300',
            ),
            SubCategoryModel(
              id: 'gsc7',
              name: 'Frozen Foods',
              imageUrl:
                  'https://images.unsplash.com/photo-1601000938259-9fc7f0206d8b?w=300',
            ),
            SubCategoryModel(
              id: 'gsc8',
              name: 'Dairy',
              imageUrl:
                  'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300',
            ),
            SubCategoryModel(
              id: 'gsc9',
              name: 'Household',
              imageUrl:
                  'https://images.unsplash.com/photo-1585421514738-01798e348b17?w=300',
            ),
            SubCategoryModel(
              id: 'gsc10',
              name: 'Personal Care',
              imageUrl:
                  'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'fresh_meat',
          name: 'Fresh Meat',
          emoji: '🥩',
          imageUrl:
              'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'm1',
              name: 'Chicken Curry Cut',
              imageUrl:
                  'https://images.unsplash.com/photo-1642391361393-6d7f95845a5f?w=300',
              price: 210,
              mrp: 240,
              rating: 4.5,
              unit: '500 g',
            ),
            FeaturedProductModel(
              id: 'm2',
              name: 'Mutton Boneless',
              imageUrl:
                  'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=300',
              price: 480,
              rating: 4.3,
              unit: '500 g',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'msc1',
              name: 'Chicken',
              imageUrl:
                  'https://images.unsplash.com/photo-1642391361393-6d7f95845a5f?w=300',
            ),
            SubCategoryModel(
              id: 'msc2',
              name: 'Mutton',
              imageUrl:
                  'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=300',
            ),
            SubCategoryModel(
              id: 'msc3',
              name: 'Seafood',
              imageUrl:
                  'https://images.unsplash.com/photo-1553247407-23251b0e7030?w=300',
            ),
            SubCategoryModel(
              id: 'msc4',
              name: 'Eggs',
              imageUrl:
                  'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'dairy',
          name: 'Dairy',
          emoji: '🥛',
          imageUrl:
              'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'd1',
              name: 'Full Cream Milk',
              imageUrl:
                  'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300',
              price: 32,
              rating: 4.6,
              unit: '500 ml',
            ),
            FeaturedProductModel(
              id: 'd2',
              name: 'Curd',
              imageUrl:
                  'https://images.unsplash.com/photo-1571212515416-fef01fc43637?w=300',
              price: 45,
              mrp: 55,
              rating: 4.4,
              unit: '400 g',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'dsc1',
              name: 'Milk',
              imageUrl:
                  'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300',
            ),
            SubCategoryModel(
              id: 'dsc2',
              name: 'Curd',
              imageUrl:
                  'https://images.unsplash.com/photo-1571212515416-fef01fc43637?w=300',
            ),
            SubCategoryModel(
              id: 'dsc3',
              name: 'Paneer',
              imageUrl:
                  'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=300',
            ),
            SubCategoryModel(
              id: 'dsc4',
              name: 'Butter & Ghee',
              imageUrl:
                  'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'bakery',
          name: 'Bakery',
          emoji: '🍞',
          imageUrl:
              'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'b1',
              name: 'Brown Bread',
              imageUrl:
                  'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
              price: 42,
              rating: 4.3,
              unit: '400 g',
            ),
            FeaturedProductModel(
              id: 'b2',
              name: 'Chocolate Cake',
              imageUrl:
                  'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300',
              price: 250,
              mrp: 300,
              rating: 4.7,
              unit: '500 g',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'bsc1',
              name: 'Bread',
              imageUrl:
                  'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=300',
            ),
            SubCategoryModel(
              id: 'bsc2',
              name: 'Cakes',
              imageUrl:
                  'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=300',
            ),
            SubCategoryModel(
              id: 'bsc3',
              name: 'Cookies',
              imageUrl:
                  'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'fruits_veg',
          name: 'Fruits & Veg',
          emoji: '🥬',
          imageUrl:
              'https://images.unsplash.com/photo-1610348725531-843dff563e2c?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'v1',
              name: 'Fresh Apple',
              imageUrl:
                  'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=300',
              price: 180,
              mrp: 210,
              rating: 4.5,
              unit: '1 kg',
            ),
            FeaturedProductModel(
              id: 'v2',
              name: 'Tomato',
              imageUrl:
                  'https://images.unsplash.com/photo-1546094324-2ec8e3f5efeb?w=300',
              price: 35,
              rating: 4.1,
              unit: '1 kg',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'vsc1',
              name: 'Fruits',
              imageUrl:
                  'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=300',
            ),
            SubCategoryModel(
              id: 'vsc2',
              name: 'Vegetables',
              imageUrl:
                  'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=300',
            ),
            SubCategoryModel(
              id: 'vsc3',
              name: 'Herbs',
              imageUrl:
                  'https://images.unsplash.com/photo-1600713137723-6a7bd5df1e7f?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'pharmacy',
          name: 'Pharmacy',
          emoji: '💊',
          imageUrl:
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'p1',
              name: 'Vitamin C Tablets',
              imageUrl:
                  'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300',
              price: 145,
              rating: 4.4,
              unit: '30 tabs',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'psc1',
              name: 'Medicines',
              imageUrl:
                  'https://images.unsplash.com/photo-1550572017-edd951b55104?w=300',
            ),
            SubCategoryModel(
              id: 'psc2',
              name: 'Wellness',
              imageUrl:
                  'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?w=300',
            ),
            SubCategoryModel(
              id: 'psc3',
              name: 'Baby Care',
              imageUrl:
                  'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'electronics',
          name: 'Electronics',
          emoji: '⚡',
          imageUrl:
              'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'e1',
              name: 'Wireless Earbuds',
              imageUrl:
                  'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300',
              price: 1499,
              mrp: 1999,
              rating: 4.2,
              unit: '1 pair',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'esc1',
              name: 'Mobiles',
              imageUrl:
                  'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=300',
            ),
            SubCategoryModel(
              id: 'esc2',
              name: 'Accessories',
              imageUrl:
                  'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'pet_store',
          name: 'Pet Store',
          emoji: '🐶',
          imageUrl:
              'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'pt1',
              name: 'Dog Food 3kg',
              imageUrl:
                  'https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=300',
              price: 899,
              rating: 4.5,
              unit: '3 kg',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'ptsc1',
              name: 'Dog Care',
              imageUrl:
                  'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=300',
            ),
            SubCategoryModel(
              id: 'ptsc2',
              name: 'Cat Care',
              imageUrl:
                  'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'flowers',
          name: 'Flowers',
          emoji: '💐',
          imageUrl:
              'https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'fl1',
              name: 'Rose Bouquet',
              imageUrl:
                  'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=300',
              price: 349,
              mrp: 399,
              rating: 4.6,
              unit: '1 bunch',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'flsc1',
              name: 'Bouquets',
              imageUrl:
                  'https://images.unsplash.com/photo-1520763185298-1b434c919102?w=300',
            ),
            SubCategoryModel(
              id: 'flsc2',
              name: 'Plants',
              imageUrl:
                  'https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=300',
            ),
          ],
        ),
      ];
}
