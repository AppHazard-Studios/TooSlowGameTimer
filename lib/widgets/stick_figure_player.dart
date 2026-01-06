import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../screens/setup_screen.dart';

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
  final VoidCallback? onDelete;
  final ValueChanged<bool> onInputToggle;

  // Visual variations
  final double headScale;
  final double torsoScale;
  final double armScale;
  final double legScale;
  final AccessoryType accessoryType;
  final PoseType poseType;
  final AnimationType animationType;

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
    required this.headScale,
    required this.torsoScale,
    required this.armScale,
    required this.legScale,
    required this.accessoryType,
    required this.poseType,
    required this.animationType,
  });

  @override
  State<StickFigurePlayer> createState() => _StickFigurePlayerState();
}

class _StickFigurePlayerState extends State<StickFigurePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _idleController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Create animation based on type
    _animation = _createAnimation();
  }

  Animation<double> _createAnimation() {
    switch (widget.animationType) {
      case AnimationType.bobbing:
        return Tween<double>(begin: 0.0, end: 1.0).animate(_idleController);
      case AnimationType.swaying:
        return Tween<double>(begin: -1.0, end: 1.0).animate(_idleController);
      case AnimationType.breathing:
        return Tween<double>(begin: 0.98, end: 1.02).animate(
          CurvedAnimation(parent: _idleController, curve: Curves.easeInOut),
        );
      case AnimationType.bouncing:
        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _idleController, curve: Curves.elasticOut),
        );
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedFigure(Widget child) {
    switch (widget.animationType) {
      case AnimationType.bobbing:
        return Transform.translate(
          offset: Offset(0, math.sin(_animation.value * math.pi) * 3),
          child: child,
        );
      case AnimationType.swaying:
        return Transform.translate(
          offset: Offset(_animation.value * 4, 0),
          child: child,
        );
      case AnimationType.breathing:
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      case AnimationType.bouncing:
        return Transform.translate(
          offset: Offset(0, -math.sin(_animation.value * math.pi) * 6),
          child: child,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return _buildAnimatedFigure(
          Column(
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
                        painter: StickFigurePainter(
                          color: widget.color,
                          headScale: widget.headScale,
                          torsoScale: widget.torsoScale,
                          armScale: widget.armScale,
                          legScale: widget.legScale,
                          accessoryType: widget.accessoryType,
                          poseType: widget.poseType,
                        ),
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
                    if (widget.onDelete != null)
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
  final double headScale;
  final double torsoScale;
  final double armScale;
  final double legScale;
  final AccessoryType accessoryType;
  final PoseType poseType;

  StickFigurePainter({
    required this.color,
    required this.headScale,
    required this.torsoScale,
    required this.armScale,
    required this.legScale,
    required this.accessoryType,
    required this.poseType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;

    // Scaled dimensions
    final headRadius = 10.0 * headScale;
    final headY = 12.0 * headScale;  // Adjust head position based on scale
    final neckY = headY + headRadius;

    final torsoLength = 28.0 * torsoScale;
    final torsoEndY = neckY + torsoLength;

    final armY = neckY + (8 * torsoScale);
    final armLength = 15.0 * armScale;

    final legLength = 25.0 * legScale;
    final legSpread = 12.0 * legScale;

    // Draw head
    canvas.drawCircle(Offset(cx, headY), headRadius, paint);

    // Draw accessory AFTER head for visibility
    _drawAccessory(canvas, paint, cx, headY, headRadius);

    // Draw torso
    canvas.drawLine(Offset(cx, neckY), Offset(cx, torsoEndY), paint);

    // Draw arms based on pose
    _drawArms(canvas, paint, cx, armY, armLength, torsoScale);

    // Draw legs
    canvas.drawLine(Offset(cx, torsoEndY), Offset(cx - legSpread, torsoEndY + legLength), paint);
    canvas.drawLine(Offset(cx, torsoEndY), Offset(cx + legSpread, torsoEndY + legLength), paint);
  }

  void _drawAccessory(Canvas canvas, Paint paint, double cx, double headY, double headRadius) {
    final accessoryPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    switch (accessoryType) {
      case AccessoryType.partyHat:
      // Triangle party hat above head - FILLED for visibility
        final hatPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        final hatPath = Path()
          ..moveTo(cx, headY - headRadius - 15)
          ..lineTo(cx - 10, headY - headRadius - 2)
          ..lineTo(cx + 10, headY - headRadius - 2)
          ..close();
        canvas.drawPath(hatPath, hatPaint);
        // Outline
        accessoryPaint.style = PaintingStyle.stroke;
        canvas.drawPath(hatPath, accessoryPaint);
        break;

      case AccessoryType.topHat:
      // Rectangle top hat - more visible
        final hatPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        // Brim
        canvas.drawRect(
          Rect.fromLTWH(cx - 12, headY - headRadius - 16, 24, 3),
          hatPaint,
        );
        // Top
        canvas.drawRect(
          Rect.fromLTWH(cx - 8, headY - headRadius - 28, 16, 12),
          hatPaint,
        );
        // Outlines
        accessoryPaint.style = PaintingStyle.stroke;
        canvas.drawRect(
          Rect.fromLTWH(cx - 12, headY - headRadius - 16, 24, 3),
          accessoryPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(cx - 8, headY - headRadius - 28, 16, 12),
          accessoryPaint,
        );
        break;

      case AccessoryType.cap:
      // Circle cap with bill
        final capPaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        // Cap dome
        canvas.drawCircle(Offset(cx, headY - headRadius - 3), 7, capPaint);
        // Bill of cap
        final billPath = Path()
          ..moveTo(cx - 7, headY - headRadius - 3)
          ..lineTo(cx + 12, headY - headRadius - 3)
          ..lineTo(cx + 10, headY - headRadius)
          ..lineTo(cx - 7, headY - headRadius)
          ..close();
        canvas.drawPath(billPath, capPaint);
        // Outlines
        accessoryPaint.style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(cx, headY - headRadius - 3), 7, accessoryPaint);
        canvas.drawPath(billPath, accessoryPaint);
        break;

      case AccessoryType.glasses:
      // Two circles for lenses - thicker for visibility
        final glassesPaint = Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(cx - 6, headY), 5, glassesPaint);
        canvas.drawCircle(Offset(cx + 6, headY), 5, glassesPaint);
        // Bridge
        canvas.drawLine(Offset(cx - 1, headY), Offset(cx + 1, headY), glassesPaint);
        break;

      case AccessoryType.none:
        break;
    }
  }

  void _drawArms(Canvas canvas, Paint paint, double cx, double armY, double armLength, double torsoScale) {
    switch (poseType) {
      case PoseType.defaultPose:
      // Arms at sides - simple and clean
        canvas.drawLine(Offset(cx, armY), Offset(cx - armLength, armY + 10), paint);
        canvas.drawLine(Offset(cx, armY), Offset(cx + armLength, armY + 10), paint);
        break;

      case PoseType.handsOnHips:
      // Arms bent at hips - adjusted for torso scale
        final bendY = armY + (8 * torsoScale);
        canvas.drawLine(Offset(cx, armY), Offset(cx - armLength * 0.7, bendY), paint);
        canvas.drawLine(Offset(cx - armLength * 0.7, bendY), Offset(cx - armLength * 0.5, bendY + 8), paint);

        canvas.drawLine(Offset(cx, armY), Offset(cx + armLength * 0.7, bendY), paint);
        canvas.drawLine(Offset(cx + armLength * 0.7, bendY), Offset(cx + armLength * 0.5, bendY + 8), paint);
        break;

    // All other poses removed - only defaultPose and handsOnHips remain
      default:
      // Fallback to default
        canvas.drawLine(Offset(cx, armY), Offset(cx - armLength, armY + 10), paint);
        canvas.drawLine(Offset(cx, armY), Offset(cx + armLength, armY + 10), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(StickFigurePainter oldDelegate) => false;
}