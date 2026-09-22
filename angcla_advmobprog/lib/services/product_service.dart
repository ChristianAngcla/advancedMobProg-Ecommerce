import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/product.dart';

class ProductService {
  // PERFORMANCE ENHANCEMENT: Paginated product fetching using limit and skip
  // Prevents lag by loading products in small, fast batches (e.g. 10 at a time)
  Future<Map<String, dynamic>> getPaginatedProducts({int limit = 10, int skip = 0}) async {
    final response = await http.get(Uri.parse('$host/products?limit=$limit&skip=$skip'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List productsRaw = data['products'] ?? [];
      final List<Product> products = productsRaw.map((json) => Product.fromJson(json)).toList();
      final int total = data['total'] ?? products.length;
      return {
        'products': products,
        'total': total,
      };
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> getAllProducts() async {
    final response = await http.get(Uri.parse('$host/products?limit=20'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List products = data['products'] ?? [];
      return products.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<Product> getProductById(int id) async {
    final response = await http.get(Uri.parse('$host/products/$id'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return Product.fromJson(data);
    } else {
      throw Exception('Failed to load product details');
    }
  }
}
