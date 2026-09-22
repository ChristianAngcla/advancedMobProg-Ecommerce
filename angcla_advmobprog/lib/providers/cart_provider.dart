import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

/// Shared cart state so adds/removes survive when switching tabs.
/// LAB ACTIVITY 4 - ENHANCEMENT 3: Supports dynamic user cart loading based on logged-in userId.
class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  int _currentUserId = 1;

  CartProvider({int userId = 1}) : _currentUserId = userId;

  List<CartProduct> _products = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  int get currentUserId => _currentUserId;
  List<CartProduct> get products => List.unmodifiable(_products);
  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get error => _error;

  double get subtotal =>
      _products.fold(0.0, (sum, item) => sum + item.total);

  double get discountedTotal =>
      _products.fold(0.0, (sum, item) => sum + item.discountedTotal);

  double get discountAmount => subtotal - discountedTotal;

  int get totalQuantity =>
      _products.fold(0, (sum, item) => sum + item.quantity);

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // Loads user cart from API using the authenticated user's ID
  Future<void> loadCart([int? newUserId]) async {
    if (newUserId != null && newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _loaded = false; // Force refresh if user changed
    }

    if (_loaded || _loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cart = await _cartService.getUserCart(_currentUserId);
      _products = List<CartProduct>.from(cart.products);
      _loaded = true;
    } catch (e) {
      _error = 'Unable to load cart from server. Please try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Force reloads the cart (useful for retry buttons)
  Future<void> retryLoadCart() async {
    _loaded = false;
    await loadCart(_currentUserId);
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _products.length) return;
    final item = _products[index];
    _products[index] = item.copyWithQuantity(item.quantity + 1);
    notifyListeners();
  }

  /// Minus decreases qty; at 0 the item is removed.
  void decreaseQuantity(int index) {
    if (index < 0 || index >= _products.length) return;
    final item = _products[index];
    if (item.quantity <= 1) {
      _products.removeAt(index);
    } else {
      _products[index] = item.copyWithQuantity(item.quantity - 1);
    }
    notifyListeners();
  }

  // Clears the cart after a confirmed order
  void clearCart() {
    _products.clear();
    _loaded = true;
    notifyListeners();
  }

  /// Calls DummyJSON add API, then updates local cart (API does not persist).
  Future<void> addProduct(Product product, {int quantity = 1}) async {
    await _cartService.addToCart(
      userId: _currentUserId,
      productId: product.id,
      quantity: quantity,
    );

    final existingIndex = _products.indexWhere((p) => p.id == product.id);
    if (existingIndex >= 0) {
      final item = _products[existingIndex];
      _products[existingIndex] =
          item.copyWithQuantity(item.quantity + quantity);
    } else {
      final lineTotal = product.price * quantity;
      final lineDiscounted =
          lineTotal * (1 - (product.discountPercentage / 100));
      _products.add(
        CartProduct(
          id: product.id,
          title: product.title,
          price: product.price,
          quantity: quantity,
          total: lineTotal,
          discountPercentage: product.discountPercentage,
          discountedTotal: lineDiscounted,
          thumbnail: product.thumbnail,
        ),
      );
    }
    _loaded = true;
    notifyListeners();
  }
}
