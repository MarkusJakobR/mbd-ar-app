import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final Function(String) onFilterTap;
  final String? selectedFilter;

  const FilterBar({super.key, required this.onFilterTap, this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    final List<String> filters = [
      'Price',
      'Material',
      'Furniture Type',
      'Brand',
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filterName = filters[index];
          final isSelected = selectedFilter == filterName;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: () => onFilterTap(filterName),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF2C2A6D)
                      : Colors.grey.shade300,
                  width: isSelected ? 2.0 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                filterName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Color(0xFF2C2A6D) : Colors.black,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
