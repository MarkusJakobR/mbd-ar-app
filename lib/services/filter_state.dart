class FilterState {
  final Set<String> selectedMaterials;
  final Set<String> selectedFurnitureTypes;
  final Set<String> selectedBrands;
  final String? selectedPriceRange;

  const FilterState({
    this.selectedMaterials = const {},
    this.selectedFurnitureTypes = const {},
    this.selectedBrands = const {},
    this.selectedPriceRange,
  });

  bool get hasActiveFilters =>
      selectedMaterials.isNotEmpty ||
      selectedFurnitureTypes.isNotEmpty ||
      selectedBrands.isNotEmpty ||
      selectedPriceRange != null;

  int get activeFilterCount =>
      (selectedMaterials.isNotEmpty ? 1 : 0) +
      (selectedFurnitureTypes.isNotEmpty ? 1 : 0) +
      (selectedBrands.isNotEmpty ? 1 : 0) +
      (selectedPriceRange != null ? 1 : 0);

  FilterState copyWith({
    Set<String>? selectedMaterials,
    Set<String>? selectedFurnitureTypes,
    Set<String>? selectedBrands,
    String? selectedPriceRange,
    bool clearPriceRange = false,
  }) {
    return FilterState(
      selectedMaterials: selectedMaterials ?? this.selectedMaterials,
      selectedFurnitureTypes:
          selectedFurnitureTypes ?? this.selectedFurnitureTypes,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      selectedPriceRange: clearPriceRange
          ? null
          : selectedPriceRange ?? this.selectedPriceRange,
    );
  }

  FilterState clear() => const FilterState();
}
