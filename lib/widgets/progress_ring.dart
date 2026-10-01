import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Anillo de progreso dibujado a mano (estilo dial de plano de construcción)
/// en vez del típico CircularProgressIndicator genérico. Anima el barrido
/// entre el valor anterior y el nuevo en vez de saltar directo, para que
/// se sienta más fluido cuando el aporte a una meta cambia su progreso.
class ProgressRing extends StatefulWidget {
  final double progress; // 0..1
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 180,
    this.strokeWidth = 14,
    required this.trackColor,
    required this.progressColor,
    this.child,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late double _target;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _target = widget.progress.clamp(0, 1).toDouble();
    _animation = _driveTween(begin: 0, end: _target);
    _controller.forward();
  }

  Animation<double> _driveTween({required double begin, required double end}) {
    return Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = widget.progress.clamp(0, 1).toDouble();
    if (newTarget != _target) {
      _animation = _driveTween(begin: _animation.value, end: newTarget);
      _target = newTarget;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, _) => CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _RingPainter(
                progress: _animation.value,
                strokeWidth: widget.strokeWidth,
                trackColor: widget.trackColor,
                progressColor: widget.progressColor,
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
