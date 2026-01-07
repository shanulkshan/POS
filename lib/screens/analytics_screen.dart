import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/sale.dart';
import '../widgets/transaction_details_dialog.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Sale> _sales = [];
  Map<String, double> _categorySales = {};
  List<Map<String, dynamic>> _chartData = [];
  String _selectedPeriod = 'Today'; // Default to Today as requested
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSalesData();
  }

  Future<void> _fetchSalesData() async {
    setState(() => _isLoading = true);
    final dbHelper = DatabaseHelper.instance;
    
    // Determine time range key for DB
    String timeRangeKey = 'day';
    if (_selectedPeriod == 'This Week') timeRangeKey = 'week';
    if (_selectedPeriod == 'This Month') timeRangeKey = 'month';
    if (_selectedPeriod == 'This Year') timeRangeKey = 'year';

    // Fetch Chart Data
    final chartData = await dbHelper.getSalesAndProfitOverTime(timeRangeKey);

    // Fetch Sales List (reusing logic but filtering by range)
    final allSales = await dbHelper.readAllSales();
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    final filteredSales = allSales.where((sale) {
      return sale.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             sale.date.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    // Aggregate category sales
    final categoryMap = <String, double>{};
    for (var sale in filteredSales) {
      final saleItems = await dbHelper.readSaleItems(sale.id!);
      for (var item in saleItems) {
        final product = await dbHelper.readProduct(item.productId);
        if (product != null) {
          final category = product.category ?? 'Uncategorized';
          categoryMap[category] = (categoryMap[category] ?? 0) + item.total;
        }
      }
    }

    if (mounted) {
      setState(() {
        _sales = filteredSales;
        _categorySales = categoryMap;
        _chartData = chartData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Analytics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        items: ['Today', 'This Week', 'This Month', 'This Year']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                            _fetchSalesData();
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sales vs Profit Line Chart
                  const Text('Sales vs Profit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      // Calculate max data value first
                      double maxDataValue = 0;
                      if (_chartData.isNotEmpty) {
                        for (var data in _chartData) {
                          double sales = (data['sales'] as double? ?? 0.0);
                          double profit = (data['profit'] as double? ?? 0.0);
                          if (sales > maxDataValue) maxDataValue = sales;
                          if (profit > maxDataValue) maxDataValue = profit;
                        }
                      }

                      // Determine interval based on maxDataValue
                      double interval = 2000;
                      if (maxDataValue > 1000000) {
                        interval = 50000;
                      } else if (maxDataValue > 100000) {
                        interval = 20000;
                      } else if (maxDataValue > 50000) {
                        interval = 5000;
                      } else {
                        interval = 2000;
                      }

                      // Calculate maxY by rounding up to the next interval
                      // Add a small buffer (e.g. 1.1x) before rounding if desired, 
                      // or just round the max value itself to the next interval.
                      // Let's round the maxDataValue up to the nearest interval.
                      double maxY = ((maxDataValue + (interval * 0.1)) / interval).ceil() * interval;
                      
                      // Ensure maxY is at least one interval
                      if (maxY == 0) maxY = interval;

                      return SizedBox(
                        height: 250,
                        child: _chartData.isEmpty 
                          ? const Center(child: Text('No data available for chart'))
                          : LineChart(
                            LineChartData(
                              maxY: maxY,
                              gridData: FlGridData(
                                show: true, 
                                drawVerticalLine: false,
                                horizontalInterval: interval,
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      int index = value.toInt();
                                      if (index >= 0 && index < _chartData.length) {
                                        String label = _chartData[index]['time_group'].toString();
                                        if (_selectedPeriod == 'Today') return Text(label, style: const TextStyle(fontSize: 10));
                                        if (_selectedPeriod == 'This Week' || _selectedPeriod == 'This Month') {
                                          if (label.length >= 10) {
                                            return Text(label.substring(5), style: const TextStyle(fontSize: 10));
                                          }
                                        }
                                        if (_selectedPeriod == 'This Year') {
                                          if (label.length >= 7) {
                                            return Text(label.substring(5), style: const TextStyle(fontSize: 10));
                                          }
                                        }
                                        return Text(label, style: const TextStyle(fontSize: 10));
                                      }
                                      return const Text('');
                                    },
                                    interval: 1,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true, 
                                    reservedSize: 50,
                                    interval: interval,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        NumberFormat.compact().format(value), 
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    },
                                  )
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                // Sales Line
                                LineChartBarData(
                                  spots: _chartData.asMap().entries.map((e) {
                                    return FlSpot(e.key.toDouble(), (e.value['sales'] as double? ?? 0.0));
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.green,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                                ),
                                // Profit Line
                                LineChartBarData(
                                  spots: _chartData.asMap().entries.map((e) {
                                    return FlSpot(e.key.toDouble(), (e.value['profit'] as double? ?? 0.0));
                                  }).toList(),
                                  isCurved: true,
                                  color: Colors.blue,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
                                ),
                              ],
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      return LineTooltipItem(
                                        '${spot.barIndex == 0 ? "Sales" : "Profit"}: ${spot.y.toStringAsFixed(2)}',
                                        TextStyle(color: spot.bar.color),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                            ),
                          ),
                      );
                    }
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 12, height: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('Sales'),
                      const SizedBox(width: 16),
                      Container(width: 12, height: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text('Profit'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Category Donut Chart
                  if (_categorySales.isNotEmpty) ...[
                    const Text('Sales by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _categorySales.entries.map((entry) {
                            final index = _categorySales.keys.toList().indexOf(entry.key);
                            final colors = [Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
                            return PieChartSectionData(
                              color: colors[index % colors.length],
                              value: entry.value,
                              showTitle: false, // Hide title on chart
                              radius: 20,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Legend
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: _categorySales.entries.map((entry) {
                        final index = _categorySales.keys.toList().indexOf(entry.key);
                        final colors = [Colors.blue, Colors.red, Colors.green, Colors.yellow, Colors.purple, Colors.orange];
                        final color = colors[index % colors.length];
                        final percentage = (entry.value / _categorySales.values.reduce((a, b) => a + b) * 100).toStringAsFixed(1);
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 12, height: 12, color: color),
                            const SizedBox(width: 4),
                            Text('${entry.key} ($percentage%)', style: const TextStyle(fontSize: 12)),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Recent Sales List
                  const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sales.length,
                    itemBuilder: (context, index) {
                      final sale = _sales[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('Sale #${sale.id}'),
                          subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(sale.date)),
                          trailing: Text(
                            'LKR ${sale.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => TransactionDetailsDialog(sale: sale),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
