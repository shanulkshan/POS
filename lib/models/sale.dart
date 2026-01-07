class Sale {
  final int? id;
  final DateTime date;
  final double totalAmount;

  Sale({
    this.id,
    required this.date,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'total_amount': totalAmount,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      date: DateTime.parse(map['date']),
      totalAmount: map['total_amount'],
    );
  }
}
