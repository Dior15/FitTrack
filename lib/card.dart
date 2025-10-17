// lib/fit_card.dart
import 'package:flutter/material.dart';

/// Section cards for the pages
class FitCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget content;

  /// Optional card for when we want 2 cards side by side
  final FitCard? sideBySide;

  // Bool for when using 1 card
  final bool _cellOnly;

  const FitCard({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
    this.sideBySide,
  }) : _cellOnly = false;

  /// Used for only single card cell.
  const FitCard.cell({
    super.key,
    required this.title,
    required this.icon,
    required this.content,
  })  : sideBySide = null,
        _cellOnly = true;

  @override
  Widget build(BuildContext context) {
    // Build the left card (this one).
    final leftCard = _buildSingleCard(
      context,
      title: title,
      icon: icon,
      content: content,
    );

    // If not pairing, return the single card.
    if (_cellOnly || sideBySide == null) {
      return leftCard;
    }

    // Build the right card using the "cell" constructor to avoid recursion.
    final rightCard = FitCard.cell(
      title: sideBySide!.title,
      icon: sideBySide!.icon,
      content: sideBySide!.content,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: leftCard),
        const SizedBox(width: 12),
        Expanded(child: rightCard),
      ],
    );
  }

  Widget _buildSingleCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Widget content,
      }) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            content,
          ],
        ),
      ),
    );
  }
}