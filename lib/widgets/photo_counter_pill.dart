import 'package:flutter/material.dart';

/// Small dark pill showing "N / M", the photo counter in full-screen
/// viewers and slideshows.
class PhotoCounterPill extends StatelessWidget {
  /// Zero-based index of the current photo.
  final int current;

  final int total;

  const PhotoCounterPill({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '${current + 1} / $total',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
