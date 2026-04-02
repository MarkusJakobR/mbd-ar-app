import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/splash_screen.dart';
import '../services/favorites_service.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'favorites_page.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  List<Product> _sharedProducts = [];
  bool _showSplash = true;
  final _favoritesService = FavoritesService();

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _favoritesService.init();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1)).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutExpo,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onProductsLoaded(List<Product> products) {
    setState(() => _sharedProducts = products);

    // Trigger splash slide out after products are ready
    _animationController.forward().then((_) {
      setState(() => _showSplash = false);
    });
  }

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app — always in tree
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(
                onProductsLoaded: _onProductsLoaded,
                favoritesService: _favoritesService,
              ),
              SearchPage(
                products: _sharedProducts,
                favoritesService: _favoritesService,
              ),
              FavoritesPage(
                allProducts: _sharedProducts,
                favoritesService: _favoritesService,
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onDestinationSelected,
            indicatorColor: const Color(0xFF2C2A6D).withOpacity(0.1),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Color(0xFF2C2A6D)),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search, color: Color(0xFF2C2A6D)),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite, color: Color(0xFF2C2A6D)),
                label: 'Favorites',
              ),
            ],
          ),
        ),

        // Splash covers everything including nav bar
        if (_showSplash)
          SlideTransition(
            position: _slideAnimation,
            child: FurnitureSplashScreen(onFinish: () {}),
          ),
      ],
    );
  }
}
