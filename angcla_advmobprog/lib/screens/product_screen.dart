import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'product_detail_screen.dart';

// LAB ACTIVITY 4 - Product Screen with Search and Infinite Scroll Pagination
// Resolves lag by loading products in small, fast batches (10 items per page)
class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _productService = ProductService();
  final ScrollController _scrollController = ScrollController();

  final List<Product> _products = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  final int _pageSize = 10;
  int _skip = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // PERFORMANCE ENHANCEMENT: Infinite scroll listener
  // Automatically loads next page when user scrolls within 200px of bottom
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _searchQuery.isEmpty) {
      _loadMoreProducts();
    }
  }

  // Loads the first batch of products
  Future<void> _fetchInitialProducts() async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
      _skip = 0;
      _hasMore = true;
      _products.clear();
    });

    try {
      final result = await _productService.getPaginatedProducts(
        limit: _pageSize,
        skip: _skip,
      );

      final List<Product> newProducts = result['products'];
      final int total = result['total'];

      setState(() {
        _products.addAll(newProducts);
        _skip += newProducts.length;
        _hasMore = _products.length < total;
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load products. Please check your internet connection.';
        _isInitialLoading = false;
      });
    }
  }

  // Loads subsequent batches when scrolling
  Future<void> _loadMoreProducts() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _productService.getPaginatedProducts(
        limit: _pageSize,
        skip: _skip,
      );

      final List<Product> newProducts = result['products'];
      final int total = result['total'];

      setState(() {
        _products.addAll(newProducts);
        _skip += newProducts.length;
        _hasMore = _products.length < total;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Filter products by title based on search query
  List<Product> get _filteredProducts {
    if (_searchQuery.trim().isEmpty) {
      return _products;
    }
    final query = _searchQuery.toLowerCase();
    return _products
        .where((p) => p.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF0038A8),
        onRefresh: _fetchInitialProducts,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0038A8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF0038A8), width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              SizedBox(height: 16.h),

              // INITIAL LOADING STATE
              if (_isInitialLoading)
                SizedBox(
                  height: 350.h,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
                    ),
                  ),
                )
              // ERROR STATE WITH RETRY
              else if (_errorMessage != null)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50.h, horizontal: 20.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.wifi_off_outlined, size: 54.sp, color: Colors.grey),
                        SizedBox(height: 12.h),
                        CustomText(
                          text: 'Unable to Load Products',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 6.h),
                        CustomText(
                          text: _errorMessage!,
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 18.h),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0038A8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          onPressed: _fetchInitialProducts,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              // EMPTY SEARCH STATE
              else if (_filteredProducts.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 50.h),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_outlined, size: 48.sp, color: Colors.grey[400]),
                        SizedBox(height: 12.h),
                        CustomText(
                          text: 'No products found',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 4.h),
                        CustomText(
                          text: 'Try searching with another keyword.',
                          fontSize: 12.sp,
                          color: Colors.grey[500],
                        ),
                      ],
                    ),
                  ),
                )
              // SUCCESS STATE: 2-COLUMN GRID WITH PAGINATION
              else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredProducts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.74,
                  ),
                  itemBuilder: (context, index) {
                    final product = _filteredProducts[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14.r),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 1,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                          side: BorderSide(color: Colors.grey.withAlpha(30)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.grey[100],
                                child: Image.network(
                                  product.thumbnail,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.image, color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(10.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    text: product.title,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: '₱${product.price.toStringAsFixed(2)}',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber[800],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // BOTTOM LOADING INDICATOR WHEN FETCHING NEXT PAGE
                if (_isLoadingMore)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0038A8)),
                        ),
                      ),
                    ),
                  ),

                // END OF CATALOG INDICATOR
                if (!_hasMore && _products.isNotEmpty && _searchQuery.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    child: Center(
                      child: CustomText(
                        text: "You've reached the end of the catalog.",
                        fontSize: 12.sp,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
