class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final int quantity;
  final double priceAtSale;

  final double discount; // Amount or percentage value
  final String discountType; // 'fixed' or 'percent'

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.priceAtSale,
    this.discount = 0.0,
    this.discountType = 'fixed',
  });

  double get total {
    double subtotal = priceAtSale * quantity;
    if (discountType == 'percent') {
      return subtotal - (subtotal * (discount / 100));
    } else {
      return subtotal - discount;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
      'discount': discount,
      'discount_type': discountType,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['sale_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      priceAtSale: map['price_at_sale'],
      discount: map['discount'] ?? 0.0,
      discountType: map['discount_type'] ?? 'fixed',
    );
  }
}
