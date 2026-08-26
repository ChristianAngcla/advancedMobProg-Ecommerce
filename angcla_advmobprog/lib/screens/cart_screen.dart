import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

// Lab Activity 3 - Enhancement 1: Make a cart_screen in order to render the new API endpoint.
// Lab Activity 3 - Enhancement 3: Integrate cart by user ID to render only one user cart.
class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, this.userId = 1});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ProductService _productService = ProductService();

  @override
  void initState() {
    super.initState();
    // Load API cart into shared CartProvider (only once)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
    });
  }

  // Enhancement 1: The items on the cart_screen must be clickable going to the detail_screen
  void _navigateToDetail(int productId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final Product product = await _productService.getProductById(productId);
      if (mounted) {
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (ctx) => ProductDetailScreen(
              product: product,
              showAddToCart: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to load product details: $e')),
        );
      }
    }
  }

  Future<void> _confirmOrder(CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text(
          'Place this order for ₱${cart.discountedTotal.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order Confirmed!'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.isLoading && !cart.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (cart.error != null && !cart.isLoaded) {
      return Center(
        child: CustomText(
          text: 'Error loading cart: ${cart.error}',
          fontSize: 14.sp,
        ),
      );
    }

    if (cart.products.isEmpty) {
      return Center(
        child: CustomText(
          text: 'Your cart is empty.',
          fontSize: 16.sp,
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(12.w),
              itemCount: cart.products.length,
              itemBuilder: (context, index) {
                final item = cart.products[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => _navigateToDetail(item.id),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              item.thumbnail,
                              width: 60.w,
                              height: 60.h,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image, size: 40.sp),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: item.title,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                CustomText(
                                  text: '₱${item.price.toStringAsFixed(2)}',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber[800],
                                ),
                                SizedBox(height: 2.h),
                                CustomText(
                                  text:
                                      '${item.discountPercentage.toStringAsFixed(0)}% off • ₱${item.discountedTotal.toStringAsFixed(2)}',
                                  fontSize: 11.sp,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              InkWell(
                                onTap: () => cart.increaseQuantity(index),
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[400],
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: const Icon(Icons.add, size: 16),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              CustomText(
                                text: '${item.quantity}',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(height: 4.h),
                              InkWell(
                                onTap: () => cart.decreaseQuantity(index),
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: const Icon(Icons.remove, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              children: [
                _priceRow('Total', '₱${cart.subtotal.toStringAsFixed(2)}'),
                SizedBox(height: 6.h),
                _priceRow(
                  'Discount',
                  '-₱${cart.discountAmount.toStringAsFixed(2)}',
                  valueColor: Colors.green[700],
                ),
                SizedBox(height: 6.h),
                _priceRow(
                  'Total Discount',
                  '₱${cart.discountedTotal.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: Colors.amber[800],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  height: 45.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    onPressed: () => _confirmOrder(cart),
                    child: CustomText(
                      text: 'Confirm Order',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          text: label,
          fontSize: isBold ? 15.sp : 14.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.grey[600],
        ),
        CustomText(
          text: value,
          fontSize: isBold ? 16.sp : 14.sp,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: valueColor,
        ),
      ],
    );
  }
}
