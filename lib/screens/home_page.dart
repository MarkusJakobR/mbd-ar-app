import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../widgets/product_grid.dart';
import '../widgets/filter_bar.dart';
import '../widgets/filter_drawer.dart';
import '../services/filter_state.dart';
import '../services/product_filter_service.dart';
import '../services/favorites_service.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<List<Product>>? onProductsLoaded;
  final FavoritesService favoritesService;

  const HomePage({
    super.key,
    this.onProductsLoaded,
    required this.favoritesService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final supabaseService = SupabaseService();
  final _filterService = ProductFilterService();

  List<Product> products = [];
  FilterState _filterState = const FilterState();
  String? activeFilter;
  bool _isLoading = false;
  String? _error;

  List<Product> get _filteredProducts =>
      _filterService.apply(products, _filterState);

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Start both the data fetch and a minimum timer (e.g., 3 seconds)
      final results = await Future.wait([
        supabaseService.getProductsFuture(),
        Future.delayed(const Duration(seconds: 4)), // Keeps splash visible
      ]);

      final List<Product> fetchedProducts = results[0] as List<Product>;

      if (mounted) {
        setState(() {
          products = fetchedProducts;
          _isLoading = false;
        });
        widget.onProductsLoaded?.call(fetchedProducts);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });

        // in case user gets stuck
        widget.onProductsLoaded?.call([]);
      }
    }
  }

  void _handleFilterTap(String filterName) {
    setState(() => activeFilter = filterName);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _applyFilters(FilterState newState) {
    setState(() => _filterState = newState);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. YOUR ORIGINAL SCAFFOLD (Kept exactly as is)
        Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(title: const Text('Furniture Catalog'), elevation: 0),
          endDrawer: FilterDrawer(
            initialFilter: activeFilter,
            currentFilterState: _filterState,
            onApply: _applyFilters,
          ),
          backgroundColor: Colors.white,
          body: Column(
            children: [
              FilterBar(
                selectedFilter: activeFilter,
                filterState: _filterState,
                onFilterTap: _handleFilterTap,
              ),
              const Divider(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Could not load products',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducts;

    if (filtered.isEmpty && _filterState.hasActiveFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No products match your filters',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  setState(() => _filterState = _filterState.clear()),
              child: const Text('Clear filters'),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchProducts,
      child: ProductGrid(
        products: filtered,
        favoritesService: widget.favoritesService,
      ), // ← filtered products
    );
  }
}
