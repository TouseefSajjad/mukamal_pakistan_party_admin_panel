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
      width: 220,
      color: Colors.black,
      child: Column(
        children: [
          _item("Dashboard", 0),
          _item("Members", 1),
          _item("Applications", 2),
          _item("Alerts", 3),
          _item("Settings", 4),
        ],
      ),
    );
  }

  Widget _item(String title, int index) {
    final isSelected = selectedIndex == index;

    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: isSelected ? Colors.green : Colors.white),
      ),
      onTap: () => onItemSelected(index),
    );
  }
}