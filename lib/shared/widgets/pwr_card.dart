import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';

/// A surface container.
///
/// Three flavours cover everything in the prototype:
///
/// * [PwrCard] — the default `#1C1C1C` block.
/// * [PwrCard.accent] — the filled purple block used for the routine the user
///   is most likely to start and for the summary hero.
/// * [PwrCard.dashed] — the outlined placeholder used for locked or
///   not-yet-created content ("Nova rotina", "Criar exercício próprio").
class PwrCard extends StatelessWidget {
  const PwrCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(PwrSpacing.lg),
    this.borderRadius = PwrRadius.cardAll,
    this.leadingAccentBar = false,
  }) : _style = _CardStyle.surface;

  const PwrCard.accent({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = PwrRadius.cardAll,
  }) : _style = _CardStyle.accent,
       leadingAccentBar = false;

  const PwrCard.dashed({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: PwrSpacing.lg,
      vertical: 18,
    ),
    this.borderRadius = PwrRadius.cardAll,
  }) : _style = _CardStyle.dashed,
       leadingAccentBar = false;

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// Draws a 3px accent bar down the left edge. Marks an exercise that is part
  /// of a superset.
  final bool leadingAccentBar;

  final _CardStyle _style;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: child);

    if (leadingAccentBar) {
      content = DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: PwrColors.accentStrong, width: 3),
          ),
        ),
        child: content,
      );
    }

    if (_style == _CardStyle.dashed) {
      return _DashedBorder(
        borderRadius: borderRadius,
        color: PwrColors.border,
        child: _tappable(content),
      );
    }

    return Material(
      color: _style == _CardStyle.accent
          ? PwrColors.accentStrong
          : PwrColors.surface,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: _tappable(content),
    );
  }

  Widget _tappable(Widget content) {
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      splashColor: _style == _CardStyle.accent
          ? PwrColors.accentDeep
          : PwrColors.surfaceRaised,
      highlightColor: Colors.transparent,
      child: content,
    );
  }
}

enum _CardStyle { surface, accent, dashed }

/// Rounded rectangle with a dashed outline.
///
/// Flutter has no dashed [BorderSide], so the stroke is painted from the
/// rounded-rect path metrics.
class _DashedBorder extends StatelessWidget {
  const _DashedBorder({
    required this.child,
    required this.borderRadius,
    required this.color,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(borderRadius: borderRadius, color: color),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.borderRadius, required this.color});

  final BorderRadius borderRadius;
  final Color color;

  static const double dashLength = 5;
  static const double gapLength = 4;
  static const double strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final path = Path()..addRRect(borderRadius.toRRect(rect));

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const step = dashLength + gapLength;
    for (final metric in path.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += step) {
        final end = (start + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius ||
        oldDelegate.color != color;
  }
}
