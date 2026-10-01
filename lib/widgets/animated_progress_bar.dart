import 'package:flutter/material.dart';

/// Barra de progreso que anima el cambio de valor (en vez del salto
/// instantáneo de un LinearProgressIndicator normal), para que se sienta
/// más fluida cuando el presupuesto o una meta cambian de estado.
///
/// Guarda su propio AnimationController para animar solo entre el valor
/// anterior y el nuevo cuando `value` realmente cambia — con
/// TweenAnimationBuilder simple, un rebuild no relacionado del padre
/// reconstruye el Tween y hace que la barra vuelva a animar desde 0 cada
/// vez, lo cual se ve como un parpadeo en vez de algo fluido.
class AnimatedProgressBar extends StatefulWidget {
  final double value;
  final double minHeight;
  final double borderRadius;
  final Color backgroundColor;
  final Color color;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.backgroundColor,
    required this.color,
    this.minHeight = 6,
    this.borderRadius = 6,
  });

  @override
  State<AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late double _target;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _target = widget.value.clamp(0, 1).toDouble();
    _animation = _driveTween(begin: 0, end: _target);
    _controller.forward();
  }

  Animation<double> _driveTween({required double begin, required double end}) {
    return Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = widget.value.clamp(0, 1).toDouble();
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => LinearProgressIndicator(
          value: _animation.value,
          minHeight: widget.minHeight,
          backgroundColor: widget.backgroundColor,
          valueColor: AlwaysStoppedAnimation(widget.color),
        ),
      ),
    );
  }
}
