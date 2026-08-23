import 'category_models.dart';

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
          id: 'pharmacy',
          name: 'Pharmacy',
          emoji: '💊',
          imageUrl:
              'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'p1',
              name: 'Paracetamol',
              imageUrl:
                  'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=300',
              price: 35,
              mrp: 40,
              rating: 4.7,
              unit: '10 tablets',
            ),
            FeaturedProductModel(
              id: 'p2',
              name: 'Vitamin C',
              imageUrl:
                  'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=300',
              price: 199,
              mrp: 249,
              rating: 4.6,
              unit: '60 capsules',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'psc1',
              name: 'Medicines',
              imageUrl:
                  'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=300',
            ),
            SubCategoryModel(
              id: 'psc2',
              name: 'Vitamins',
              imageUrl:
                  'https://images.unsplash.com/photo-1607619056574-7b8d3ee536b2?w=300',
            ),
            SubCategoryModel(
              id: 'psc3',
              name: 'Personal Care',
              imageUrl:
                  'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=300',
            ),
          ],
        ),
        CategoryModel(
          id: 'pets',
          name: 'Pets',
          emoji: '🐶',
          imageUrl:
              'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=200',
          featuredProducts: [
            FeaturedProductModel(
              id: 'pet1',
              name: 'Dog Food',
              imageUrl:
                  'https://images.unsplash.com/photo-1586671267731-da2cf3ceeb80?w=300',
              price: 499,
              mrp: 549,
              rating: 4.8,
              unit: '3 kg',
            ),
            FeaturedProductModel(
              id: 'pet2',
              name: 'Cat Food',
              imageUrl:
                  'https://images.unsplash.com/photo-1519052537078-e6302a4968d4?w=300',
              price: 399,
              mrp: 449,
              rating: 4.7,
              unit: '2 kg',
            ),
          ],
          subCategories: const [
            SubCategoryModel(
              id: 'petsc1',
              name: 'Dog',
              imageUrl:
                  'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=300',
            ),
            SubCategoryModel(
              id: 'petsc2',
              name: 'Cat',
              imageUrl:
                  'https://images.unsplash.com/photo-1519052537078-e6302a4968d4?w=300',
            ),
            SubCategoryModel(
              id: 'petsc3',
              name: 'Accessories',
              imageUrl:
                  'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=300',
            ),
          ],
        ),
      ];
}
