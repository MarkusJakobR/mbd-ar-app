class FilterOptions {
  static const List<String> priceRanges = [
    'Under ₱100',
    '₱100 - ₱500',
    '₱500 - ₱1000',
    'Over ₱1000',
  ];

  static const List<String> materials = [
    'Wood',
    'Metal',
    'Fabric',
    'Plastic',
    'Glass',
    'Leather',
  ];

  static const List<String> furnitureTypes = [
    'Chair',
    'Table',
    'Sofa',
    'Bed',
    'Cabinet',
    'Desk',
    'Shelf',
  ];

  static const List<String> brands = ['IKEA', 'West Elm', 'Wayfair', 'Ashley'];

  // Price range to min/max values for filtering
  static (double min, double max) parsePriceRange(String range) {
    switch (range) {
      case 'Under ₱100':
        return (0, 100);
      case '₱100 - ₱500':
        return (100, 500);
      case '₱500 - ₱1000':
        return (500, 1000);
      case 'Over ₱1000':
        return (1000, double.infinity);
      default:
        return (0, double.infinity);
    }
  }
}
