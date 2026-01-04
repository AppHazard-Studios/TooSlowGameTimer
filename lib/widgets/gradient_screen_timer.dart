import 'package:flutter/material.dart';

class GradientScreenTimer extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onComplete;

  const GradientScreenTimer({
    super.key,
    required this.durationSeconds,
    required this.onComplete,
  });

  @override
  State<GradientScreenTimer> createState() => _GradientScreenTimerState();
}

class _GradientScreenTimerState extends State<GradientScreenTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    )..addListener(() => setState(() {}));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getTopColor() {
    if (_animation.value < 0.4) return const Color(0xFF4CAF50); // Green
    if (_animation.value < 0.7) return const Color(0xFFFFEB3B); // Yellow
    return const Color(0xFFFF5252); // Red
  }

  Color _getBottomColor() {
    if (_animation.value < 0.4) return const Color(0xFF81C784);
    if (_animation.value < 0.7) return const Color(0xFFFFD54F);
    return const Color(0xFFFF8A80);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: GradientTimerPainter(
        progress: _animation.value,
        topColor: _getTopColor(),
        bottomColor: _getBottomColor(),
      ),
      child: Container(),
    );
  }
}

class GradientTimerPainter extends CustomPainter {
  final double progress;
  final Color topColor;
  final Color bottomColor;

  GradientTimerPainter({
    required this.progress,
    required this.topColor,
    required this.bottomColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [topColor, bottomColor],
      stops: [progress - 0.1, progress + 0.1],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(GradientTimerPainter oldDelegate) => true;
}