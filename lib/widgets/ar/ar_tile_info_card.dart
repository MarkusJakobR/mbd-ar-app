import 'package:flutter/material.dart';

class ARTileInfoCard extends StatelessWidget {
  final String productName;
  final int minTileCount;
  final int maxTileCount;
  final double minTotalCost;
  final double maxTotalCost;
  final double totalArea;

  const ARTileInfoCard({
    super.key,
    required this.productName,
    required this.minTileCount,
    required this.maxTileCount,
    required this.minTotalCost,
    required this.maxTotalCost,
    required this.totalArea,
  });

  String get _tileCountText {
    if (maxTileCount == 1) return '1 tile';
    if (minTileCount == maxTileCount) return '$minTileCount tiles';
    return '$minTileCount - $maxTileCount tiles';
  }

  String get _costText {
    if (maxTileCount == 1) return '₱ ${maxTotalCost.toStringAsFixed(2)}';
    if (minTileCount == maxTileCount)
      return '₱ ${minTotalCost.toStringAsFixed(2)}';
    return '₱ ${minTotalCost.toStringAsFixed(2)} - ${maxTotalCost.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 32,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_on, color: Color(0xFF2C2A6D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _InfoColumn(label: 'Estimated tiles', value: _tileCountText),
                if (minTotalCost > 0)
                  _InfoColumn(label: 'Total cost', value: _costText),
                if (totalArea > 0)
                  _InfoColumn(
                    label: 'Total area',
                    value: '${totalArea.toStringAsFixed(2)} m²',
                    crossAxisAlignment: CrossAxisAlignment.end,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment crossAxisAlignment;

  const _InfoColumn({
    required this.label,
    required this.value,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C2A6D),
          ),
        ),
      ],
    );
  }
}
