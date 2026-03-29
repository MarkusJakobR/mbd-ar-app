import 'package:flutter/material.dart';
import 'package:mbd_ar_app/widgets/splash_screen.dart';
import '../models/product.dart';
import '../services/supabase_service.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_search_delegate.dart';
import '../widgets/filter_bar.dart';
import '../widgets/filter_drawer.dart';
import '../services/filter_state.dart';
import '../services/product_filter_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  List<Product> get _filteredProducts =>
      _filterService.apply(products, _filterState);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Speed of the scroll up
    );

    _slideAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0, -1), // Move UP by 100% of screen height
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutExpo, // A "premium" feeling curve
          ),
        );
    _fetchProducts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        });

        _animationController.forward().then((_) {
          setState(() {
            _isLoading =
                false; // Completely remove it from the tree after it slides off
          });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
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
          appBar: AppBar(
            title: const Text('Furniture Catalog'),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchProducts,
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: ProductSearchDelegate(allProducts: products),
                  );
                },
              ),
            ],
          ),
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

        // 2. THE SLIDING LAYER (Only visible while loading)
        if (_isLoading)
          SlideTransition(
            position: _slideAnimation, // Uses the controller we set up
            child: FurnitureSplashScreen(onFinish: () {}),
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
      child: ProductGrid(products: filtered), // ← filtered products
    );
  }
}
