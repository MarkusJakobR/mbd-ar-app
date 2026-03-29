import '../models/product.dart';
import 'filter_state.dart';
import 'filter_options.dart';

class ProductFilterService {
  // Client-side filtering — easy to swap to server-side later
  List<Product> apply(List<Product> products, FilterState filters) {
    if (!filters.hasActiveFilters) return products;

    return products.where((product) {
      // Price filter
      if (filters.selectedPriceRange != null) {
        final (min, max) = FilterOptions.parsePriceRange(
          filters.selectedPriceRange!,
        );
        if (product.price < min || product.price > max) return false;
      }

      // Material filter — AND logic: product must match at least one selected
      if (filters.selectedMaterials.isNotEmpty) {
        final match = filters.selectedMaterials.any(
          (m) => product.material.toLowerCase() == m.toLowerCase(),
        );
        if (!match) return false;
      }

      // Furniture type filter
      if (filters.selectedFurnitureTypes.isNotEmpty) {
        final match = filters.selectedFurnitureTypes.any(
          (t) => product.category.toLowerCase() == t.toLowerCase(),
        );
        if (!match) return false;
      }

      // Brand filter
      if (filters.selectedBrands.isNotEmpty) {
        final match = filters.selectedBrands.any(
          (b) => product.brand.toLowerCase() == b.toLowerCase(),
        );
        if (!match) return false;
      }

      return true;
    }).toList();
  }
}
