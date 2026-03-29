import 'package:flutter/material.dart';
import '../services/filter_options.dart';
import '../services/filter_state.dart';

class PriceFilter extends StatelessWidget {
  final FilterState filterState;
  final ValueChanged<FilterState> onChanged;

  const PriceFilter({
    super.key,
    required this.filterState,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: FilterOptions.priceRanges.map((range) {
        final isSelected = filterState.selectedPriceRange == range;
        return RadioListTile<String>(
          title: Text(range),
          value: range,
          groupValue: filterState.selectedPriceRange,
          onChanged: (val) {
            onChanged(
              isSelected
                  // Tap again to deselect
                  ? filterState.copyWith(clearPriceRange: true)
                  : filterState.copyWith(selectedPriceRange: val),
            );
          },
          activeColor: const Color(0xFF2C2A6D),
          contentPadding: EdgeInsets.zero,
          selected: isSelected,
        );
      }).toList(),
    );
  }
}
