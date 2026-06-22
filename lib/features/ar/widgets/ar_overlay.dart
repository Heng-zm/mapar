import 'dart:math' as math;

import 'package:flutter/material.dart';

class AROverlay extends StatelessWidget {
  const AROverlay({
    super.key,
    required this.arrowDegrees,
    required this.instruction,
    required this.distanceText,
    required this.progress,
    required this.headingText,
    required this.speedText,
  });

  final double arrowDegrees;
  final String instruction;
  final String distanceText;
  final double progress;
  final String headingText;
  final String speedText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: _ARGridPainter(color: scheme.primary.withValues(alpha: 0.18))),
        ),
        Positioned(
          top: 48,
          left: 24,
          right: 24,
          child: _HudCard(
            child: Column(
              children: [
                Text(instruction, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(distanceText, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
              ],
            ),
          ),
        ),
        Center(
          child: Transform.rotate(
            angle: arrowDegrees * math.pi / 180,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.14),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.65), width: 2),
              ),
              child: Icon(Icons.navigation, size: 82, color: scheme.primary),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 124,
          child: Row(
            children: [
              Expanded(child: _HudCard(child: _Telemetry(label: 'Heading', value: headingText))),
              const SizedBox(width: 12),
              Expanded(child: _HudCard(child: _Telemetry(label: 'Speed', value: speedText))),
            ],
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HudCard extends StatelessWidget {
  const _HudCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: scheme.surface.withValues(alpha: 0.82),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: child,
    );
  }
}

class _Telemetry extends StatelessWidget {
  const _Telemetry({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ARGridPainter extends CustomPainter {
  _ARGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final horizon = size.height * 0.58;
    for (var i = 0; i < 9; i++) {
      final y = horizon + i * 34;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (var i = -5; i <= 5; i++) {
      final startX = size.width / 2 + i * 24;
      canvas.drawLine(Offset(startX, horizon), Offset(size.width / 2 + i * 90, size.height), paint);
    }
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width / 2 - 24, size.height / 2), Offset(size.width / 2 + 24, size.height / 2), crossPaint);
    canvas.drawLine(Offset(size.width / 2, size.height / 2 - 24), Offset(size.width / 2, size.height / 2 + 24), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _ARGridPainter oldDelegate) => oldDelegate.color != color;
}
