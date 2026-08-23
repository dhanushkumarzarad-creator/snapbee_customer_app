import 'package:flutter/material.dart';

class FlashSaleWidget extends StatelessWidget {
  final VoidCallback? onShopTap;

  const FlashSaleWidget({super.key, this.onShopTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            // Flash Sale Image
            Transform.translate(
              offset: const Offset(-12, 0),
              child: SizedBox(
                width: 180,
                height: 180,
                child: Image.asset(
                  'assets/images/flash_sale/flash_sale.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Offer Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Flash Sale',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Up to 70% OFF',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ends in 02:15:43',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // Shop Button
            ElevatedButton(
              onPressed: onShopTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Shop',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
