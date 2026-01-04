import 'package:flutter/material.dart';
import 'dart:math' as math;

class StickFigurePlayer extends StatefulWidget {
  final Color color;
  final TextEditingController nameController;
  final bool showingInput;
  final int playerNumber;
  final bool showOrderControls;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDelete;
  final ValueChanged<bool> onInputToggle;

  const StickFigurePlayer({
    super.key,
    required this.color,
    required this.nameController,
    required this.showingInput,
    required this.playerNumber,
    required this.showOrderControls,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDelete,
    required this.onInputToggle,
  });

  @override
  State<StickFigurePlayer> createState() => _StickFigurePlayerState();
}

class _StickFigurePlayerState extends State<StickFigurePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _idleController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, math.sin(_idleController.value * math.pi) * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Stick figure with controls
              SizedBox(
                width: 100,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Stick figure centered
                    Positioned(
                      left: 20,
                      top: 8,
                      child: CustomPaint(
                        size: const Size(60, 80),
                        painter: StickFigurePainter(color: widget.color),
                      ),
                    ),

                    // Player number badge (top left)
                    if (widget.showOrderControls)
                      Positioned(
                        top: -4,
                        left: -4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.playerNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Delete button (top right)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: widget.onDelete,
                        onTapDown: (_) {},
                        onTapUp: (_) {},
                        onTapCancel: () {},
                        onLongPress: () {},
                        onLongPressStart: (_) {},
                        onLongPressEnd: (_) {},
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),

                    // Up arrow (bottom left)
                    if (widget.showOrderControls && widget.canMoveUp)
                      Positioned(
                        bottom: -4,
                        left: -4,
                        child: GestureDetector(
                          onTap: widget.onMoveUp,
                          onTapDown: (_) {},
                          onTapUp: (_) {},
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_upward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),

                    // Down arrow (bottom right)
                    if (widget.showOrderControls && widget.canMoveDown)
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: widget.onMoveDown,
                          onTapDown: (_) {},
                          onTapUp: (_) {},
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: widget.color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Name input/display
              if (widget.showingInput || widget.nameController.text.isEmpty)
                Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.color, width: 2),
                  ),
                  child: widget.showingInput
                      ? TextField(
                    controller: widget.nameController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Name',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) {
                      if (widget.nameController.text.trim().isNotEmpty) {
                        widget.onInputToggle(false);
                      }
                    },
                  )
                      : GestureDetector(
                    onTap: () => widget.onInputToggle(true),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      height: 24,
                      child: Center(
                        child: Text(
                          'Tap to name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.color.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  onTap: () => widget.onInputToggle(true),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: widget.color, width: 2),
                    ),
                    child: Text(
                      widget.nameController.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class StickFigurePainter extends CustomPainter {
  final Color color;

  StickFigurePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;

    canvas.drawCircle(Offset(cx, 12), 10, paint);
    canvas.drawLine(Offset(cx, 22), Offset(cx, 50), paint);
    canvas.drawLine(Offset(cx, 30), Offset(cx - 15, 40), paint);
    canvas.drawLine(Offset(cx, 30), Offset(cx + 15, 40), paint);
    canvas.drawLine(Offset(cx, 50), Offset(cx - 12, 75), paint);
    canvas.drawLine(Offset(cx, 50), Offset(cx + 12, 75), paint);
  }

  @override
  bool shouldRepaint(StickFigurePainter oldDelegate) => false;
}