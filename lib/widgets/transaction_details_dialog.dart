import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/sale.dart';

class TransactionDetailsDialog extends StatelessWidget {
  final Sale sale;

  const TransactionDetailsDialog({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sale #${sale.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            DateFormat('yyyy-MM-dd HH:mm').format(sale.date),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: DatabaseHelper.instance.getSaleItemsWithProduct(sale.id!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Text('No items found.');
            }

            final items = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                final quantity = item['quantity'] as int;
                final price = item['price_at_sale'] as double;
                final discount = item['discount'] as double;
                final discountType = item['discount_type'] as String;
                final productName = item['product_name'] as String;
                
                double total = price * quantity;
                if (discountType == 'percent') {
                  total -= total * (discount / 100);
                } else {
                  total -= discount;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$quantity x LKR ${price.toStringAsFixed(2)}'),
                      if (discount > 0)
                        Text(
                          'Discount: ${discountType == 'percent' ? '$discount%' : 'LKR $discount'}',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Text(
                    'LKR ${total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
