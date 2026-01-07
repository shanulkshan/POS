import 'package:flutter/material.dart';
import '../models/product.dart';
import '../db/database_helper.dart';

class InventoryProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    _products = await DatabaseHelper.instance.readAllProducts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.createProduct(product);
    await fetchProducts();
  }

  Future<void> updateProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    await fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    await fetchProducts();
  }
  
  Future<Product?> getProductByBarcode(String barcode) async {
    return await DatabaseHelper.instance.getProductByBarcode(barcode);
  }
  
  Future<void> refresh() async {
    await fetchProducts();
  }
}
