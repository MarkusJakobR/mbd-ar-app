import 'package:flutter/material.dart';
import '../services/filter_state.dart';
import '../services/filter_options.dart';
import 'filter_price.dart';
import 'filter_checklist.dart';

class FilterDrawer extends StatefulWidget {
  final String? initialFilter; // The one clicked from the HomeBar
  final FilterState currentFilterState;
  final ValueChanged<FilterState> onApply;

  const FilterDrawer({
    super.key,
    this.initialFilter,
    required this.currentFilterState,
    required this.onApply,
  });

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  // Track which accordion is open. -1 means all are closed.
  int _openIndex = -1;
  late FilterState _localState;

  final List<String> _filterCategories = [
    'Price',
    'Material',
    'Furniture Type',
    'Brand',
  ];

  @override
  void initState() {
    super.initState();
    _localState = widget.currentFilterState;
    // When the drawer opens, automatically expand the one the user clicked on
    if (widget.initialFilter != null) {
      _openIndex = _filterCategories.indexOf(widget.initialFilter!);
    }
  }

  void _updateFilter(FilterState updated) {
    setState(() => _localState = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _filterCategories.length,
                itemBuilder: (context, index) {
                  return _buildFilterAccordion(index);
                },
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              if (_localState.hasActiveFilters)
                TextButton(
                  onPressed: () =>
                      setState(() => _localState = _localState.clear()),
                  child: const Text(
                    'Clear all',
                    style: TextStyle(color: Color(0xFF2C2A6D)),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAccordion(int index) {
    final category = _filterCategories[index];
    final bool isOpen = _openIndex == index;

    return Theme(
      // This removes the default border lines from ExpansionTile
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: Key('${category}_${isOpen}'),
        initiallyExpanded: isOpen,
        onExpansionChanged: (expanded) {
          setState(() {
            // If expanded, set this as open index; if collapsed, set to -1
            _openIndex = expanded ? index : -1;
          });
        },
        // IKEA style: Bold the title if it's the active one
        title: Row(
          children: [
            Text(
              category,
              style: TextStyle(
                color: isOpen ? const Color(0xFF2C2A6D) : Colors.black87,
                fontWeight: isOpen ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (_getCategoryActiveCount(category) > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2A6D),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_getCategoryActiveCount(category)}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: _buildCategoryContent(category),
          ),
        ],
      ),
    );
  }

  int _getCategoryActiveCount(String category) {
    switch (category) {
      case 'Price':
        return _localState.selectedPriceRange != null ? 1 : 0;
      case 'Material':
        return _localState.selectedMaterials.length;
      case 'Furniture Type':
        return _localState.selectedFurnitureTypes.length;
      case 'Brand':
        return _localState.selectedBrands.length;
      default:
        return 0;
    }
  }

  Widget _buildCategoryContent(String category) {
    // This is where we will eventually put your Supabase data logic
    switch (category) {
      case 'Price':
        return PriceFilter(filterState: _localState, onChanged: _updateFilter);
      case 'Material':
        return ChecklistFilter(
          options: FilterOptions.materials,
          selected: _localState.selectedMaterials,
          onChanged: (updated) =>
              _updateFilter(_localState.copyWith(selectedMaterials: updated)),
        );
      case 'Furniture Type':
        return ChecklistFilter(
          options: FilterOptions.furnitureTypes,
          selected: _localState.selectedFurnitureTypes,
          onChanged: (updated) => _updateFilter(
            _localState.copyWith(selectedFurnitureTypes: updated),
          ),
        );
      case 'Brand':
        return ChecklistFilter(
          options: FilterOptions.brands,
          selected: _localState.selectedBrands,
          onChanged: (updated) =>
              _updateFilter(_localState.copyWith(selectedBrands: updated)),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter(context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C2A6D),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          widget.onApply(_localState);
          Navigator.pop(context);
        },
        child: const Text(
          'Show Results',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
