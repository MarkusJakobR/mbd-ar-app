import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final Function(String) onFilterTap;

  const FilterBar({super.key, required this.onFilterTap});

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
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: () => onFilterTap(filters[index]),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(
                filters[index],
                style: const TextStyle(color: Colors.black, fontSize: 13),
              ),
            ),
          );
        },
      ),
    );
  }
}
