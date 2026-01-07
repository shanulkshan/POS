
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../widgets/main_layout.dart';
import 'inventory_screen.dart';
import 'billing_screen.dart';
import 'analytics_screen.dart';
import 'package:provider/provider.dart';
import 'notification_screen.dart';
import '../providers/inventory_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/custom_toast.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {
    'totalSales': 0.0,
    'totalOrders': 0,
    'totalProfit': 0.0,
  };
  bool _isLoading = true;

  String _selectedTimeRange = 'day';

  Future<void> _loadStats() async {
    final stats = await DatabaseHelper.instance.getDashboardStats(_selectedTimeRange);
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  void _onItemSelected(int index) async {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
      _loadStats();
    } else if (index == 2) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const BillingScreen()));
      _loadStats();
    } else if (index == 3) {
      await Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen()));
      _loadStats();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Check for low stock on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLowStock();
    });
  }

  void _checkLowStock() {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final hasNewAlerts = Provider.of<NotificationProvider>(context, listen: false).checkLowStock(inventory.products);
    
    if (hasNewAlerts) {
      CustomToast.show(context, 'Low Stock Warning!', isWarning: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger low stock check whenever inventory changes
    final inventory = Provider.of<InventoryProvider>(context);
    
    // We use addPostFrameCallback to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
       _checkLowStock();
    });

    return MainLayout(
      title: 'Dashboard',
      selectedIndex: _selectedIndex,
      onItemSelected: _onItemSelected,
      actions: [
        Consumer<NotificationProvider>(
          builder: (context, notifications, child) {
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
                    );
                  },
                ),
                if (notifications.unreadCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '${notifications.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedTimeRange,
                  underline: Container(),
                  icon: const Icon(Icons.calendar_today, size: 20),
                  items: const [
                    DropdownMenuItem(value: 'day', child: Text('Today')),
                    DropdownMenuItem(value: 'week', child: Text('This Week')),
                    DropdownMenuItem(value: 'month', child: Text('This Month')),
                    DropdownMenuItem(value: 'year', child: Text('This Year')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTimeRange = value;
                        _isLoading = true;
                      });
                      _loadStats();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = width > 900 ? 4 : (width > 600 ? 2 : 1);
                // Decrease aspect ratio for mobile to make cards taller (width / height)
                // Mobile: 1 column. Width ~360. Ratio 2.0 -> Height ~180.
                double childAspectRatio = width > 900 ? 1.5 : (width > 600 ? 1.8 : 2.0);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildStatCard(
                      'Total Sales',
                      'LKR ${NumberFormat('#,##0.00').format(_stats['totalSales'])}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Total Profit',
                      'LKR ${NumberFormat('#,##0.00').format(_stats['totalProfit'])}',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Orders',
                      '${_stats['totalOrders']}',
                      Icons.shopping_bag,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Low Stock',
                      '${inventory.products.where((p) => p.stockQuantity <= p.lowStockLimit).length}',
                      Icons.warning_amber,
                      Colors.red,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionButton(
                  context,
                  'New Sale',
                  Icons.point_of_sale,
                  Colors.blue,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BillingScreen()),
                    );
                    _loadStats();
                  },
                ),
                _buildActionButton(
                  context,
                  'Add Product',
                  Icons.add_box,
                  Colors.green,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const InventoryScreen()),
                    );
                    _loadStats();
                  },
                ),
                _buildActionButton(
                  context,
                  'Analytics',
                  Icons.bar_chart,
                  Colors.purple,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                    _loadStats();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: 150,
      height: 110, // Increased height to prevent overflow
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // Reduced horizontal padding
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
