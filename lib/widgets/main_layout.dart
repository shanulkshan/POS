import 'package:flutter/material.dart';
import 'sidebar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String? title;
  final List<Widget>? actions;

  const MainLayout({
    super.key,
    required this.child,
    this.selectedIndex = 0,
    this.onItemSelected = _defaultOnItemSelected,
    this.title,
    this.actions,
  });

  static void _defaultOnItemSelected(int index) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
            )
          : null,
      body: Row(
        children: [
          // Sidebar is always visible on tablet/desktop, hidden on small mobile if needed
          // For this V2, we'll keep it visible as a persistent rail
          Sidebar(
            selectedIndex: selectedIndex,
            onItemSelected: onItemSelected,
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
