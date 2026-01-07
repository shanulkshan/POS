import 'package:flutter/material.dart';
import '../widgets/pos_product_grid.dart';
import '../widgets/pos_cart_sidebar.dart';
import '../widgets/custom_toast.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';


class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isPriceCheckerMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBarcodeScanned(String code) {
    if (!mounted) return;
    
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final product = inventoryProvider.products.firstWhere(
      (p) => p.barcode == code,
      orElse: () => Product(name: '', barcode: '', price: 0, stockQuantity: 0),
    );

    if (product.id != null) {
      if (_isPriceCheckerMode) {
        _showPriceCheckDialog(product);
      } else {
        Provider.of<CartProvider>(context, listen: false).addItem(product);
        CustomToast.show(context, 'Added ${product.name} to cart');
      }
    } else {
      CustomToast.show(context, 'Product not found', isError: true);
    }
  }

  void _showPriceCheckDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.imagePath != null)
              Image.file(File(product.imagePath!), height: 100, width: 100, fit: BoxFit.cover),
            const SizedBox(height: 16),
            Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('LKR ${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Stock: ${product.stockQuantity}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<CartProvider>(context, listen: false).addItem(product);
              CustomToast.show(context, 'Added to cart');
            },
            child: const Text('Add to Cart'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showManualPriceDialog() {
    final priceController = TextEditingController();
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Item Entry'),
        scrollable: true,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name (Optional)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price', prefixText: 'LKR '),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price != null) {
                final product = Product(
                  id: -1, // Temporary ID
                  name: nameController.text.isNotEmpty ? nameController.text : 'Manual Item',
                  barcode: '',
                  price: price,
                  stockQuantity: 999,
                  category: 'Manual',
                );
                Provider.of<CartProvider>(context, listen: false).addItem(product);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('POS Terminal'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isPriceCheckerMode ? Icons.price_check : Icons.shopping_cart),
            color: _isPriceCheckerMode ? Colors.green : Colors.black,
            tooltip: _isPriceCheckerMode ? 'Price Checker Mode ON' : 'Switch to Price Checker',
            onPressed: () {
              setState(() {
                _isPriceCheckerMode = !_isPriceCheckerMode;
              });
              CustomToast.show(context, _isPriceCheckerMode ? 'Price Checker Mode Enabled' : 'Sales Mode Enabled');
            },
          ),
          IconButton(
            icon: const Icon(Icons.dialpad),
            tooltip: 'Manual Entry',
            onPressed: _showManualPriceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              // Prevent multiple scans
              bool isScanned = false;
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Scan Barcode')),
                    body: MobileScanner(
                      onDetect: (capture) {
                        if (isScanned) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String? code = barcodes.first.rawValue;
                          if (code != null) {
                            isScanned = true;
                            Navigator.pop(context, code);
                          }
                        }
                      },
                    ),
                  ),
                ),
              );
              if (result != null) {
                _onBarcodeScanned(result);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                
                // Use Row layout for tablets and landscape phones (width > 600)
                if (constraints.maxWidth > 600) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 2, // Reverted to 2
                        child: POSProductGrid(
                          searchQuery: _searchController.text,
                          onProductSelected: (product) {
                            if (_isPriceCheckerMode) {
                              _showPriceCheckDialog(product);
                            } else {
                              Provider.of<CartProvider>(context, listen: false).addItem(product);
                            }
                          },
                        ),
                      ),
                      const VerticalDivider(width: 1),
                      const Expanded(
                        flex: 1, // Reverted to 1
                        child: POSCartSidebar(isMobile: true),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(
                        child: POSProductGrid(
                          searchQuery: _searchController.text,
                          onProductSelected: (product) {
                            if (_isPriceCheckerMode) {
                              _showPriceCheckDialog(product);
                            } else {
                              Provider.of<CartProvider>(context, listen: false).addItem(product);
                              CustomToast.show(context, 'Added to cart');
                            }
                          },
                        ),
                      ),
                      if (!isKeyboardOpen) ...[
                        const Divider(height: 1),
                        SizedBox(
                          height: constraints.maxHeight * 0.5, // Reverted to 0.5
                          child: const POSCartSidebar(isMobile: true),
                        ),
                      ],
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
