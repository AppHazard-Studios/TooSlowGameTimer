import 'package:flutter/material.dart';
import 'dart:math' as math;

class CircularTimer extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onComplete;

  const CircularTimer({
    super.key,
    required this.durationSeconds,
    required this.onComplete,
  });

  @override
  State<CircularTimer> createState() => _CircularTimerState();
}

class _CircularTimerState extends State<CircularTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller)
      ..addListener(() => setState(() {}));

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    final remaining = (_animation.value * widget.durationSeconds).ceil();
    if (remaining > 6) return Colors.white;
    if (remaining > 3) return const Color(0xFFFFEB3B);
    return const Color(0xFFFF5252);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_animation.value * widget.durationSeconds).ceil();

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: CircularTimerPainter(
              progress: _animation.value,
              color: _getColor(),
            ),
          ),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: _getColor(),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class CircularTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  CircularTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircularTimerPainter oldDelegate) => true;
}