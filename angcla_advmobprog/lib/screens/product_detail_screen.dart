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
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await cartProvider.addProduct(product);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully added "${product.title}" to cart!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Product Details',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.network(
                product.thumbnail,
                width: double.infinity,
                height: 220.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    height: 220.h,
                    child: const Center(child: Icon(Icons.image, size: 48)),
                  );
                },
              ),
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: product.title,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: '₱${product.price.toStringAsFixed(2)}',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: 'Category: ${product.category}',
              fontSize: 14.sp,
            ),
            if (product.brand.isNotEmpty) ...[
              SizedBox(height: 4.h),
              CustomText(
                text: 'Brand: ${product.brand}',
                fontSize: 14.sp,
              ),
            ],
            SizedBox(height: 4.h),
            CustomText(
              text: 'Rating: ${product.rating}',
              fontSize: 14.sp,
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: 'Description',
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 8.h),
            CustomText(
              text: product.description,
              fontSize: 14.sp,
            ),
            if (showAddToCart) ...[
              SizedBox(height: 24.h),
              // Enhancement 3: Add to Cart button widget
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: CustomText(
                    text: 'Add to Cart',
                    fontSize: 16.sp,
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
