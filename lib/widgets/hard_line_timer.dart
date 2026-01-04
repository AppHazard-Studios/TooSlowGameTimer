import 'package:flutter/material.dart';

enum WipeDirection { down, up, left, right }

class HardLineTimer extends StatefulWidget {
  final int durationSeconds;
  final Color startColor;
  final Color endColor;
  final WipeDirection direction;
  final VoidCallback onComplete;

  const HardLineTimer({
    super.key,
    required this.durationSeconds,
    required this.startColor,
    required this.endColor,
    required this.direction,
    required this.onComplete,
  });

  @override
  State<HardLineTimer> createState() => _HardLineTimerState();
}

class _HardLineTimerState extends State<HardLineTimer>
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final remaining = ((1 - _animation.value) * widget.durationSeconds).ceil();

    return Stack(
      children: [
        // Start color (being consumed)
        Positioned.fill(
          child: Container(color: widget.startColor),
        ),

        // End color (consuming)
        _buildWipeOverlay(size),

        // Countdown
        Center(
          child: Text(
            '$remaining',
            style: TextStyle(
              fontSize: 300,
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.2),
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWipeOverlay(Size size) {
    switch (widget.direction) {
      case WipeDirection.down:
        return Positioned(
          top: size.height * _animation.value,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(color: widget.endColor),
        );
      case WipeDirection.up:
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: size.height * (1 - _animation.value),
          child: Container(color: widget.endColor),
        );
      case WipeDirection.left:
        return Positioned(
          top: 0,
          left: 0,
          right: size.width * (1 - _animation.value),
          bottom: 0,
          child: Container(color: widget.endColor),
        );
      case WipeDirection.right:
        return Positioned(
          top: 0,
          left: size.width * _animation.value,
          right: 0,
          bottom: 0,
          child: Container(color: widget.endColor),
        );
    }
  }
}