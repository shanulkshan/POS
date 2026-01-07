import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../db/database_helper.dart';

class CartItem {
  final Product product;
  int quantity;
  double discount;
  String discountType; // 'fixed' or 'percent'

  CartItem({
    required this.product, 
    this.quantity = 1,
    this.discount = 0.0,
    this.discountType = 'fixed',
  });
  
  double get total {
    double baseTotal = product.price * quantity;
    if (discountType == 'percent') {
      return baseTotal - (baseTotal * (discount / 100));
    } else {
      return baseTotal - discount;
    }
  }
}

class CartProvider with ChangeNotifier {
  Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.total;
    });
    return total;
  }
  
  int get itemCount {
    return _items.length;
  }

  void addItem(Product product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id!,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity + 1,
          discount: existingCartItem.discount,
          discountType: existingCartItem.discountType,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id!,
        () => CartItem(product: product),
      );
    }
    notifyListeners();
  }

  void updateDiscount(int productId, double discount, String type) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity,
          discount: discount,
          discountType: type,
        ),
      );
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          product: existingCartItem.product,
          quantity: existingCartItem.quantity - 1,
          discount: existingCartItem.discount,
          discountType: existingCartItem.discountType,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: quantity,
          discount: existing.discount,
          discountType: existing.discountType,
        ),
      );
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
  
  Future<void> checkout() async {
    final date = DateTime.now();
    final sale = Sale(date: date, totalAmount: totalAmount);
    final saleId = await DatabaseHelper.instance.createSale(sale);
    
    for (var cartItem in _items.values) {
      final saleItem = SaleItem(
        saleId: saleId,
        productId: cartItem.product.id!,
        quantity: cartItem.quantity,
        priceAtSale: cartItem.product.price,
        discount: cartItem.discount,
        discountType: cartItem.discountType,
      );
      await DatabaseHelper.instance.createSaleItem(saleItem);
      
      // Update stock
      final newStock = cartItem.product.stockQuantity - cartItem.quantity;
      final updatedProduct = Product(
        id: cartItem.product.id,
        name: cartItem.product.name,
        barcode: cartItem.product.barcode,
        price: cartItem.product.price,
        stockQuantity: newStock,
        category: cartItem.product.category,
        description: cartItem.product.description,
        purchasePrice: cartItem.product.purchasePrice,
        imagePath: cartItem.product.imagePath,
      );
      await DatabaseHelper.instance.updateProduct(updatedProduct);
    }
    clear();
  }
}
