import 'package:flutter/material.dart';

/// Responsive score-card sizing for phones (small / regular / large) and tablets.
class ScoreCardLayout {
  final double cardWidth;
  final double cardHeight;
  final double cardSpacing;
  final double cardPadding;
  final double titleFontSize;
  final bool compactLayout;

  const ScoreCardLayout({
    required this.cardWidth,
    required this.cardHeight,
    required this.cardSpacing,
    required this.cardPadding,
    required this.titleFontSize,
    required this.compactLayout,
  });

  static ScoreCardLayout of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final shortestSide = size.shortestSide;

    // Tablet: iPad, Android tablets, large foldables
    if (shortestSide >= 600) {
      return const ScoreCardLayout(
        cardWidth: 220,
        cardHeight: 78,
        cardSpacing: 20,
        cardPadding: 10,
        titleFontSize: 15,
        compactLayout: false,
      );
    }

    // Small phone (e.g. iPhone SE, compact Android)
    if (width < 360) {
      return const ScoreCardLayout(
        cardWidth: 148,
        cardHeight: 76,
        cardSpacing: 8,
        cardPadding: 6,
        titleFontSize: 12,
        compactLayout: true,
      );
    }

    // Regular phone (most iPhones / Android)
    if (width < 400) {
      return const ScoreCardLayout(
        cardWidth: 165,
        cardHeight: 80,
        cardSpacing: 10,
        cardPadding: 8,
        titleFontSize: 13,
        compactLayout: true,
      );
    }

    if (width < 600) {
      return const ScoreCardLayout(
        cardWidth: 130,
        cardHeight: 77,
        cardSpacing: 15,
        cardPadding: 8,
        titleFontSize: 14,
        compactLayout: false,
      );
    }

    // Wide layout (landscape phone, foldable inner display)
    return const ScoreCardLayout(
      cardWidth: 200,
      cardHeight: 88,
      cardSpacing: 16,
      cardPadding: 8,
      titleFontSize: 14,
      compactLayout: false,
    );
  }
}
