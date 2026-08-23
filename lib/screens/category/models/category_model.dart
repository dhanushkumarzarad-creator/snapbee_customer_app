class CategoryModel {
  final String id;
  final String name;
  final String image;
  final String color;

  final List<ProductModel> featuredProducts;
  final List<SubCategoryModel> subCategories;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.color,
    required this.featuredProducts,
    required this.subCategories,
  });

  static List<CategoryModel> categories = [
    CategoryModel(
      id: "foods",
      name: "Foods",
      image: "assets/images/categories/foods.png",
      color: "#FFE0B2",
      featuredProducts: [
        ProductModel(
          name: "Chicken Biryani",
          image: "assets/images/products/biryani.png",
          price: "₹199",
        ),
        ProductModel(
          name: "Parotta",
          image: "assets/images/products/parotta.png",
          price: "₹60",
        ),
        ProductModel(
          name: "Fried Rice",
          image: "assets/images/products/fried_rice.png",
          price: "₹149",
        ),
      ],
      subCategories: [
        SubCategoryModel(
          name: "Cafe",
          image: "assets/images/subcategories/cafe.png",
        ),
        SubCategoryModel(
          name: "Meals",
          image: "assets/images/subcategories/meals.png",
        ),
        SubCategoryModel(
          name: "Biryani",
          image: "assets/images/subcategories/biryani.png",
        ),
        SubCategoryModel(
          name: "Parotta",
          image: "assets/images/subcategories/parotta.png",
        ),
      ],
    ),

    CategoryModel(
      id: "grocery",
      name: "Grocery",
      image: "assets/images/categories/grocery.png",
      color: "#E8F5E9",
      featuredProducts: [],
      subCategories: [],
    ),

    CategoryModel(
      id: "meat",
      name: "Fresh Meat",
      image: "assets/images/categories/fresh_meat.png",
      color: "#FBE9E7",
      featuredProducts: [],
      subCategories: [],
    ),

    CategoryModel(
      id: "pharmacy",
      name: "Pharmacy",
      image: "assets/images/categories/pharmacy.png",
      color: "#E3F2FD",
      featuredProducts: [],
      subCategories: [],
    ),
  ];
}

class ProductModel {
  final String id;
  final String name;
  final String image;
  final String price;
  final double priceValue;

  /// `products.vendor_id`, carried through so tapping a featured product
  /// card can add it to the cart — see product_details_screen.dart, which
  /// refuses to add any product with an empty vendorId.
  final String vendorId;

  const ProductModel({
    this.id = '',
    required this.name,
    required this.image,
    required this.price,
    this.priceValue = 0,
    this.vendorId = '',
  });
}

class SubCategoryModel {
  final String name;
  final String image;

  const SubCategoryModel({required this.name, required this.image});
}
