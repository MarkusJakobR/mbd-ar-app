import 'package:flutter/material.dart';

class FilterDrawer extends StatefulWidget {
  final String? initialFilter; // The one clicked from the HomeBar

  const FilterDrawer({super.key, this.initialFilter});

  @override
  State<FilterDrawer> createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  // Track which accordion is open. -1 means all are closed.
  int _openIndex = -1;

  final List<String> _filterCategories = [
    'Price',
    'Material',
    'Furniture Type',
    'Brand',
  ];

  @override
  void initState() {
    super.initState();
    // When the drawer opens, automatically expand the one the user clicked on
    if (widget.initialFilter != null) {
      _openIndex = _filterCategories.indexOf(widget.initialFilter!);
    }
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
            _buildFooter(),
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
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
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
        title: Text(
          category,
          style: TextStyle(
            color: isOpen ? const Color(0xFF2C2A6D) : Colors.black87,
            fontWeight: isOpen ? FontWeight.bold : FontWeight.w500,
          ),
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

  Widget _buildCategoryContent(String category) {
    // This is where we will eventually put your Supabase data logic
    switch (category) {
      case 'Price':
        return const Text("Price Range Slider will go here...");
      case 'Material':
        return _buildChecklist(['Wood', 'Metal', 'Fabric', 'Plastic']);
      case 'Furniture Type':
        return _buildChecklist(['Chair', 'Table', 'Sofa', 'Bed']);
      case 'Brand':
        return _buildChecklist(['IKEA', 'West Elm', 'Wayfair']);
      default:
        return const SizedBox();
    }
  }

  Widget _buildChecklist(List<String> options) {
    return Column(
      children: options.map((option) {
        return CheckboxListTile(
          title: Text(option),
          value: false, // We will handle state here in the next step
          onChanged: (val) {},
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: const Color(0xFF2C2A6D),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
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
        onPressed: () => Navigator.pop(context),
        child: const Text(
          'Show Results',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
