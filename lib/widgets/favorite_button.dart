import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/favorites_service.dart';

class FavoriteButton extends StatelessWidget {
  final Product product;
  final FavoritesService favoritesService;
  final double size;
  final Color activeColor;
  final Color inactiveColor;

  const FavoriteButton({
    super.key,
    required this.product,
    required this.favoritesService,
    this.size = 24,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: favoritesService,
      builder: (context, _) {
        final isFav = favoritesService.isFavorite(product.id);

        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? activeColor : inactiveColor,
            size: size,
          ),
          onPressed: () => favoritesService.toggleFavorite(product),
        );
      },
    );
  }
}
