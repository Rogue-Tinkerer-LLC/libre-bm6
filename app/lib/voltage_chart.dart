import 'dart:math';

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

/// A scrolling line of recent voltages, labelled with its min and max.
class VoltageChart extends StatelessWidget {
  const VoltageChart({super.key, required this.voltages});

  final List<double> voltages;

  @override
  Widget build(BuildContext context) {
    if (voltages.length < 2) return const SizedBox(height: 120);
    final l = AppLocalizations.of(context);
    final low = l.voltageValue(voltages.reduce(min));
    final high = l.voltageValue(voltages.reduce(max));
    return Semantics(
      label: l.chartSemantics(low, high),
      child: CustomPaint(
        size: const Size.fromHeight(120),
        painter: _ChartPainter(
          voltages: voltages,
          low: low,
          high: high,
          style: Theme.of(context).textTheme.labelSmall!,
          textScaler: MediaQuery.textScalerOf(context),
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.voltages,
    required this.low,
    required this.high,
    required this.style,
    required this.textScaler,
    required this.color,
  });

  final List<double> voltages;
  final String low;
  final String high;
  final TextStyle style;
  final TextScaler textScaler;
  final Color color;

  TextPainter _label(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(color: color),
    ),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final top = _label(high);
    final bottom = _label(low);
    final lo = voltages.reduce(min);
    final span = max(voltages.reduce(max) - lo, 0.01);
    final plotTop = top.height;
    final plotHeight = size.height - top.height - bottom.height;
    final dx = size.width / (voltages.length - 1);
    final path = Path();
    for (var i = 0; i < voltages.length; i++) {
      final y = plotTop + plotHeight * (1 - (voltages[i] - lo) / span);
      i == 0 ? path.moveTo(0, y) : path.lineTo(i * dx, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    top.paint(canvas, Offset.zero);
    bottom.paint(canvas, Offset(0, size.height - bottom.height));
  }

  // A new painter is only built when a frame arrives, ~once per second.
  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => true;
}
