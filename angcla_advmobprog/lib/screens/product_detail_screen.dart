import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';

// Enhancement 1 & 2: Detail screen widget for viewing product details
class ProductDetailScreen extends StatelessWidget {
  final Product product;
  // Hide Add to Cart when opening details from the cart
  final bool showAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.showAddToCart = true,
  });

  // Enhancement 3: Add product to cart by passing values to POST /carts/add endpoint
  void _addToCart(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adding product to cart via API...'),
        duration: Duration(milliseconds: 800),
      ),
    );

    try {
      await cartProvider.addProduct(product);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added "${product.title}" to cart!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to add product to cart. Please check your internet connection.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        title: CustomText(
          text: 'Product Details',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Hero Image Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                product.thumbnail,
                width: double.infinity,
                height: 220.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 220.h,
                    child: const Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
                  );
                },
              ),
            ),
            SizedBox(height: 18.h),

            // Product Title
            CustomText(
              text: product.title,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),

            // Price Tag
            CustomText(
              text: '₱${product.price.toStringAsFixed(2)}',
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.amber[800],
            ),
            SizedBox(height: 12.h),

            // Category & Rating Badges
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: CustomText(
                    text: product.category.toUpperCase(),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0038A8),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(35),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 4.w),
                      CustomText(
                        text: product.rating.toString(),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (product.brand.isNotEmpty) ...[
              SizedBox(height: 10.h),
              CustomText(
                text: 'Brand: ${product.brand}',
                fontSize: 13.sp,
                color: Colors.grey[700],
              ),
            ],
            SizedBox(height: 18.h),

            // Description Header
            CustomText(
              text: 'Description',
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 6.h),
            CustomText(
              text: product.description,
              fontSize: 13.sp,
              color: Colors.grey[600],
            ),

            if (showAddToCart) ...[
              SizedBox(height: 28.h),
              // Add to Cart Button Widget
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    elevation: 1,
                  ),
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.add_shopping_cart, size: 20),
                  label: CustomText(
                    text: 'Add to Cart',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
