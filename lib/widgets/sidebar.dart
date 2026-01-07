import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      color: Colors.white,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.motorcycle, size: 40, color: Colors.orange),
                const SizedBox(height: 40),
                _buildNavItem(0, Icons.dashboard, 'Home'),
                _buildNavItem(1, Icons.inventory_2, 'Inventory'),
                _buildNavItem(2, Icons.point_of_sale, 'POS'),
                _buildNavItem(3, Icons.analytics, 'Reports'),
                const Spacer(),
                _buildNavItem(4, Icons.settings, 'Settings'),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemSelected(index),
      child: Container(
        height: 70,
        width: double.infinity,
        decoration: isSelected
            ? const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.orange, width: 4),
                ),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.orange : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
