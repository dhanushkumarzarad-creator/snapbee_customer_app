import 'package:flutter/material.dart';

class CategoryHeader extends StatelessWidget {
  const CategoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Categories",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.favorite_border, size: 26),
        ),

        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none, size: 26),
        ),

        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shopping_cart_outlined, size: 26),
            ),

            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  "2",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
