import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

/// Shared cart state so adds/removes survive when switching tabs.
class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  final int userId;

  CartProvider({this.userId = 1});

  List<CartProduct> _products = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<CartProduct> get products => List.unmodifiable(_products);
  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get error => _error;

  double get subtotal =>
      _products.fold(0.0, (sum, item) => sum + item.total);

  double get discountedTotal =>
      _products.fold(0.0, (sum, item) => sum + item.discountedTotal);

  double get discountAmount => subtotal - discountedTotal;

  /// Load user cart from API once; later edits stay in memory.
  Future<void> loadCart() async {
    if (_loaded || _loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cart = await _cartService.getUserCart(userId);
      _products = List<CartProduct>.from(cart.products);
      _loaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
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

  /// Calls DummyJSON add API, then updates local cart (API does not persist).
  Future<void> addProduct(Product product, {int quantity = 1}) async {
    await _cartService.addToCart(
      userId: userId,
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
