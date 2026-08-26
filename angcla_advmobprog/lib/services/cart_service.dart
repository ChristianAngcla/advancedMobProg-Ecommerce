import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/cart.dart';

// Lab Activity 3 - Service Layer for handling Cart API HTTP requests
class CartService {
  // Enhancement 1: Fetch all carts endpoint (GET /carts)
  Future<List<Cart>> getAllCarts() async {
    final response = await http.get(Uri.parse('$host/carts'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      return cartsJson.map((json) => Cart.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load carts');
    }
  }

  // Enhancement 3: Integrate cart by user ID (getById) to render only one user cart (GET /carts/user/{id})
  Future<Cart> getUserCart(int userId) async {
    final response = await http.get(Uri.parse('$host/carts/user/$userId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List cartsJson = data['carts'] ?? [];
      if (cartsJson.isNotEmpty) {
        return Cart.fromJson(cartsJson.first);
      }
    }

    // Fallback: Query cart by cart ID directly
    final cartRes = await http.get(Uri.parse('$host/carts/$userId'));
    if (cartRes.statusCode == 200) {
      return Cart.fromJson(jsonDecode(cartRes.body));
    }

    throw Exception('Failed to load user cart for ID $userId');
  }

  // Enhancement 3: Add to cart API endpoint (POST /carts/add)
  Future<Map<String, dynamic>> addToCart({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$host/carts/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'products': [
          {
            'id': productId,
            'quantity': quantity,
          }
        ],
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add product to cart');
    }
  }
}
