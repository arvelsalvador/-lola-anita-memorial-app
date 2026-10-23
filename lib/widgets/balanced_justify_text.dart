import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Justified text whose line breaks are chosen up front so no line is left
/// much shorter than its neighbours.
///
/// Flutter's [TextAlign.justify] reuses the greedy line breaker used by
/// left-aligned text: when the next word is long, the current line stays
/// short and the leftover width is spread across its word gaps. In a narrow
/// card column that produces the notorious rivers of white space. This widget
/// first picks the break points with a minimum-raggedness pass, then renders
/// the result as ordinary justified [Text], so the remaining stretch is small
/// and evenly distributed.
///
/// Only single-paragraph copy is re-broken; text containing explicit newlines
/// is passed through untouched (the caller keeps its own paragraph handling).
class BalancedJustifyText extends StatelessWidget {
  const BalancedJustifyText(
    this.text, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.justify,
    this.maxLines,
    this.overflow,
    this.semanticsLabel,
  });

  final String text;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? semanticsLabel;

  // Cards are static, so the same (text, style, width) is laid out on every
  // rebuild. A small cache keeps the measuring pass off the scroll path.
  // Records compare structurally, so a cache entry can never be served for a
  // different paragraph (as a plain int hash could on a collision).
  static final Map<Object, String> _cache = <Object, String>{};
  static const int _cacheLimit = 128;

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = DefaultTextStyle.of(context).style.merge(style);
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth || constraints.maxWidth <= 0) {
          return _render(text);
        }
        final width = constraints.maxWidth;
        final balanced = _balanced(
          text: text,
          style: resolvedStyle,
          maxWidth: width,
          textScaler: textScaler,
          textDirection: textDirection,
          locale: locale,
        );
        // Tight width: justification must fill the card column, not the
        // longest re-broken line.
        return SizedBox(width: width, child: _render(balanced));
      },
    );
  }

  Widget _render(String value) => Text(
        value,
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        semanticsLabel: semanticsLabel,
      );

  static String _balanced({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
    required Locale? locale,
  }) {
    if (text.contains('\n')) return text;
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return text;

    final key = (text, style, maxWidth, textScaler, textDirection, locale);
    final cached = _cache[key];
    if (cached != null) return cached;

    final measured = <String, double>{};
    double measure(String value) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        locale: locale,
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final widths = <double>[];
    for (final word in words) {
      widths.add(measured.putIfAbsent(word, () => measure(word)));
    }
    final space = measure(' ');

    // A little headroom so the real renderer never re-wraps a manual line.
    final limit = math.max(1.0, maxWidth - 0.5);
    final n = words.length;
    final prefix = List<double>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + widths[i];
    }
    double lineWidth(int start, int end) =>
        prefix[end] - prefix[start] + space * (end - start - 1);

    // Minimum-raggedness DP. Cost is the squared leftover per line; the last
    // line is free, as in every justified typesetter.
    final best = List<double>.filled(n + 1, double.infinity);
    final next = List<int>.filled(n + 1, -1);
    best[n] = 0;

    for (var start = n - 1; start >= 0; start--) {
      for (var end = start + 1; end <= n; end++) {
        final width = lineWidth(start, end);
        final oversized = width > limit;
        if (oversized && end > start + 1) break;

        final slack = math.max(0.0, limit - width);
        final lineCost = end == n ? 0.0 : slack * slack;
        final total = lineCost + best[end];
        if (total < best[start]) {
          best[start] = total;
          next[start] = end;
        }

        // A single word wider than the column can only be a line of its own.
        if (oversized) break;
      }
    }

    final lines = <String>[];
    var start = 0;
    while (start < n) {
      final end = next[start];
      if (end <= start) {
        lines.add(words.sublist(start).join(' '));
        break;
      }
      lines.add(words.sublist(start, end).join(' '));
      start = end;
    }

    final result = lines.join('\n');
    if (_cache.length >= _cacheLimit) _cache.clear();
    _cache[key] = result;
    return result;
  }
}
