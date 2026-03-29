import 'package:flutter/material.dart';
import '../services/filter_state.dart';

class FilterBar extends StatelessWidget {
  final Function(String) onFilterTap;
  final String? selectedFilter;
  final FilterState filterState;

  const FilterBar({
    super.key,
    required this.onFilterTap,
    required this.filterState,
    this.selectedFilter,
  });

  // How many active selections per category
  int _getActiveCount(String filterName) {
    switch (filterName) {
      case 'Price':
        return filterState.selectedPriceRange != null ? 1 : 0;
      case 'Material':
        return filterState.selectedMaterials.length;
      case 'Furniture Type':
        return filterState.selectedFurnitureTypes.length;
      case 'Brand':
        return filterState.selectedBrands.length;
      default:
        return 0;
    }
  }

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
          final activeCount = _getActiveCount(filterName);
          final hasActive = activeCount > 0;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: OutlinedButton(
              onPressed: () => onFilterTap(filterName),
              style: OutlinedButton.styleFrom(
                // Active filter = filled background, selected = just border
                backgroundColor: hasActive
                    ? const Color(0xFFF9BE2C)
                    : Colors.transparent,
                side: BorderSide(
                  color: hasActive || isSelected
                      ? const Color(0xFFF9BE2C)
                      : Colors.grey.shade300,
                  width: hasActive || isSelected ? 2.0 : 1.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filterName,
                    style: TextStyle(
                      fontWeight: hasActive || isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: hasActive
                          ? Color(0xFF2C2A6D)
                          : isSelected
                          ? const Color(0xFF2C2A6D)
                          : Colors.black,
                      fontSize: 13,
                    ),
                  ),
                  // Show count badge inline if active
                  if (hasActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          color: Color(0xFF2C2A6D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
