class Product {
  final int? id;
  final String name;
  final String barcode;
  final double price;
  final int stockQuantity;
  final String? category;
  final String? description;

  final double? purchasePrice;
  final String? imagePath;
  final String? brand;
  final int lowStockLimit;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stockQuantity,
    this.category,
    this.description,
    this.purchasePrice,
    this.imagePath,
    this.brand,
    this.lowStockLimit = 5,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock_quantity': stockQuantity,
      'category': category,
      'description': description,
      'purchase_price': purchasePrice,
      'image_path': imagePath,
      'brand': brand,
      'low_stock_limit': lowStockLimit,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      price: map['price'],
      stockQuantity: map['stock_quantity'],
      category: map['category'],
      description: map['description'],
      purchasePrice: map['purchase_price'],
      imagePath: map['image_path'],
      brand: map['brand'],
      lowStockLimit: map['low_stock_limit'] ?? 5,
    );
  }
}
