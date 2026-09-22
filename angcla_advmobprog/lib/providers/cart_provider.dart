import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

/// Shared cart state so adds/removes survive when switching tabs.
/// LAB ACTIVITY 4 - ENHANCEMENT 3: Supports dynamic user cart loading based on logged-in userId.
/// LAB ACTIVITY 5 - FIREBASE CART COMPATIBILITY: Isolates Firebase users with an in-memory cart.
class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final UserService _userService = UserService();
  int _currentUserId = 1;
  bool _isFirebaseUser = false;

  CartProvider({int userId = 1}) : _currentUserId = userId;

  List<CartProduct> _products = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  int get currentUserId => _currentUserId;
  bool get isFirebaseUser => _isFirebaseUser;
  List<CartProduct> get products => List.unmodifiable(_products);
  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get error => _error;

  double get subtotal => _products.fold(0.0, (sum, item) => sum + item.total);

  double get discountedTotal =>
      _products.fold(0.0, (sum, item) => sum + item.discountedTotal);

  double get discountAmount => subtotal - discountedTotal;

  int get totalQuantity =>
      _products.fold(0, (sum, item) => sum + item.quantity);

  // LAB ACTIVITY 4 - ENHANCEMENT 3
  // LAB ACTIVITY 5 - FIREBASE CART COMPATIBILITY
  // Loads user cart from API using the authenticated user's ID or initializes empty cart for Firebase users
  Future<void> loadCart(int? newUserId, {bool isFirebaseUser = false}) async {
    // When the user ID or login type changes:
    if ((newUserId != null && newUserId != _currentUserId) ||
        isFirebaseUser != _isFirebaseUser) {
      if (newUserId != null) {
        _currentUserId = newUserId;
      }
      _isFirebaseUser = isFirebaseUser;
      _loaded = false;
      _products.clear();
    }

    // If isFirebaseUser is true:
    // Do not call CartService or DummyJSON, mark as loaded, keep cart empty, notify listeners, return
    if (isFirebaseUser) {
      _loaded = true;
      _loading = false;
      _error = null;
      notifyListeners();
      return;
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

  // LAB ACTIVITY 5 - FIREBASE CART COMPATIBILITY
  // Force reloads the cart using the saved Firebase/DummyJSON type
  Future<void> retryLoadCart() async {
    _loaded = false;
    await loadCart(_currentUserId, isFirebaseUser: _isFirebaseUser);
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

  // LAB ACTIVITY 5 - FIREBASE CART COMPATIBILITY
  // Adds product to cart: skips DummyJSON API if Firebase user, otherwise calls DummyJSON API
  Future<void> addProduct(Product product, {int quantity = 1}) async {
    final user = await _userService.getUser();
    await loadCart(user.id, isFirebaseUser: user.isFirebaseUser);

    if (!user.isFirebaseUser) {
      await _cartService.addToCart(
        userId: _currentUserId,
        productId: product.id,
        quantity: quantity,
      );
    }

    final existingIndex = _products.indexWhere((p) => p.id == product.id);
    if (existingIndex >= 0) {
      final item = _products[existingIndex];
      _products[existingIndex] = item.copyWithQuantity(
        item.quantity + quantity,
      );
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
