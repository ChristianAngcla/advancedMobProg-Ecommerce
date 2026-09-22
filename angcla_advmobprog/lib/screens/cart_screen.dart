import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/product_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

// LAB ACTIVITY 4 - ENHANCEMENT 3
// Cart Screen with dynamic user-based cart loading, polished Material 3 order confirmation modal, and improved error/empty states.
class CartScreen extends StatefulWidget {
  final int? userId;

  const CartScreen({super.key, this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final ProductService _productService = ProductService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeUserCart();
  }

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // LAB ACTIVITY 5 - FIREBASE CART COMPATIBILITY
  // Retrieves saved user data from SharedPreferences to load the user's specific cart safely
  void _initializeUserCart() async {
    int targetUserId = widget.userId ?? 1;

    try {
      final user = await _userService.getUser();
      // LAB ACTIVITY 5 - FIREBASE CART COMPATIBILITY
      if (user.isFirebaseUser) {
        if (!mounted) return;
        context.read<CartProvider>().loadCart(0, isFirebaseUser: true);
        return;
      } else if (user.id > 0) {
        targetUserId = user.id;
      }
    } catch (_) {
      // Fallback to default user ID if not yet available
    }

    if (!mounted) return;
    context.read<CartProvider>().loadCart(targetUserId, isFirebaseUser: false);
  }

  // Enhancement 1: Click cart item card to navigate to detail screen
  void _navigateToDetail(int productId) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final Product product = await _productService.getProductById(productId);
      if (mounted) {
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (ctx) =>
                ProductDetailScreen(product: product, showAddToCart: false),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to load product details. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // CONFIRMATION MODAL ENHANCEMENT
  // Material 3 bottom sheet modal with complete order summary and confirmation actions
  void _showOrderConfirmationModal(BuildContext context, CartProvider cart) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 32.h),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 18.h),

              // Title with Cart Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Color(0xFF0038A8),
                  ),
                  SizedBox(width: 8.w),
                  CustomText(
                    text: 'Confirm Your Order',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              CustomText(
                text: 'Please review your order summary below:',
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
              SizedBox(height: 20.h),

              // Order Summary Container
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.withAlpha(40)),
                ),
                child: Column(
                  children: [
                    _priceRow('Total Items', '${cart.totalQuantity} items'),
                    SizedBox(height: 8.h),
                    _priceRow(
                      'Subtotal',
                      '₱${cart.subtotal.toStringAsFixed(2)}',
                    ),
                    SizedBox(height: 8.h),
                    _priceRow(
                      'Discount Savings',
                      '-₱${cart.discountAmount.toStringAsFixed(2)}',
                      valueColor: Colors.green[700],
                    ),
                    const Divider(height: 20),
                    _priceRow(
                      'Final Amount',
                      '₱${cart.discountedTotal.toStringAsFixed(2)}',
                      isBold: true,
                      valueColor: Colors.amber[800],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Action Buttons (Cancel and Confirm)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => Navigator.pop(modalContext),
                      child: CustomText(
                        text: 'Cancel',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0038A8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(modalContext); // Close modal
                        cart.clearCart(); // Complete order and clear items

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Order Confirmed! Thank you for your purchase.',
                            ),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        );
                      },
                      child: CustomText(
                        text: 'Place Order',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    // LOADING STATE
    if (cart.isLoading && !cart.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
        ),
      );
    }

    // ERROR STATE WITH RETRY BUTTON
    if (cart.error != null && !cart.isLoaded) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 54.sp, color: Colors.grey),
              SizedBox(height: 12.h),
              CustomText(
                text: 'Unable to Load Cart',
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              SizedBox(height: 6.h),
              CustomText(
                text: cart.error ?? 'Please check your internet connection.',
                fontSize: 13.sp,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0038A8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                onPressed: () => cart.retryLoadCart(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // EMPTY STATE
    if (cart.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 60.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            CustomText(
              text: 'Your Cart is Empty',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            SizedBox(height: 6.h),
            CustomText(
              text: 'Explore the shop to add items to your cart.',
              fontSize: 13.sp,
              color: Colors.grey[500],
            ),
          ],
        ),
      );
    }

    // SUCCESS STATE: RENDER CART ITEMS
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
                    side: BorderSide(color: Colors.grey.withAlpha(30)),
                  ),
                  elevation: 0.8,
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
                              width: 64.w,
                              height: 64.h,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.image, size: 40.sp),
                            ),
                          ),
                          SizedBox(width: 14.w),
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
          // Bottom Subtotal and Checkout Bar
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
                  'Total after Discount',
                  '₱${cart.discountedTotal.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: Colors.amber[800],
                ),
                SizedBox(height: 14.h),
                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    onPressed: () => _showOrderConfirmationModal(context, cart),
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
