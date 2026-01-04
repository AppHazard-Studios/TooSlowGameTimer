import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../widgets/stick_figure_player.dart';
import 'game_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> with TickerProviderStateMixin {
  final List<PlayerData> _players = [];
  String _selectedMode = GameConstants.modes[1];
  int _timerDuration = GameConstants.defaultTimerSeconds;
  bool _isLongPressing = false;
  late AnimationController _longPressController;
  late AnimationController _pulseController; // ADD THIS
  late Animation<double> _pulseAnimation; // ADD THIS

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _longPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
      if (_longPressController.isCompleted && mounted) {
        _startGame();
      }
      setState(() {});
    });

    // ADD PULSE ANIMATION
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reset animation when returning to this screen
    if (_longPressController.value > 0) {
      _longPressController.reset();
      setState(() => _isLongPressing = false);
    }
  }

  @override
  void dispose() {
    _longPressController.dispose();
    _pulseController.dispose(); // ADD THIS
    for (var player in _players) {
      player.controller.dispose();
    }
    super.dispose();
  }

  void _movePlayerUp(int index) {
    if (index == 0) return; // Already at top

    HapticFeedback.selectionClick();
    setState(() {
      final temp = _players[index];
      _players[index] = _players[index - 1];
      _players[index - 1] = temp;
    });
  }

  void _movePlayerDown(int index) {
    if (index == _players.length - 1) return; // Already at bottom

    HapticFeedback.selectionClick();
    setState(() {
      final temp = _players[index];
      _players[index] = _players[index + 1];
      _players[index + 1] = temp;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isLongPressing) return;

    final size = MediaQuery.of(context).size;
    double tapX = details.localPosition.dx;
    double tapY = details.localPosition.dy;

    // Block bottom area
    if (tapY > size.height - 240) return;

    // Don't add new player if current player hasn't been named
    if (_players.isNotEmpty && _players.last.controller.text.trim().isEmpty) {
      _showMessage('Name the current player first!');
      HapticFeedback.mediumImpact();
      return;
    }

    // Close all existing name inputs AND auto-name if empty
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].showingInput && _players[i].controller.text.trim().isEmpty) {
        _players[i].controller.text = 'Player ${i + 1}'; // Auto-assign
      }
      _players[i].showingInput = false;
    }
    FocusScope.of(context).unfocus();

    // Clamp tap position
    if (tapY < 50) tapY = 50 + 20;
    if (tapY > size.height - 230 - 20) tapY = size.height - 250;

    // Figure dimensions
    final figureHeight = 170.0;
    final figureWidth = 140.0;

    double widgetLeft = tapX - 70;
    double widgetTop = tapY - 12;

    // Adjust bounds
    if (widgetLeft < 10) widgetLeft = 10;
    if (widgetLeft > size.width - figureWidth - 10) {
      widgetLeft = size.width - figureWidth - 10;
    }

    final maxBottom = size.height - 230;
    if (widgetTop + figureHeight > maxBottom) {
      widgetTop = maxBottom - figureHeight;
    }

    if (widgetTop < 50) widgetTop = 50;

    final relativeX = tapX / size.width;
    final relativeY = tapY / size.height;

    HapticFeedback.lightImpact();

    setState(() {
      _players.add(PlayerData(
        controller: TextEditingController(),
        color: _getPlayerColor(_players.length),
        absolutePosition: Offset(widgetLeft, widgetTop),
        position: Offset(relativeX, relativeY),
        showingInput: true,
      ));
    });
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    final position = details.localPosition;
    final size = MediaQuery.of(context).size;

    // Only allow long press on bottom area AND prevent it from triggering tap
    if (position.dy > size.height - 220) {
      HapticFeedback.selectionClick();
      setState(() => _isLongPressing = true);
      _longPressController.forward();
      // Don't call _handleTapDown - long press is separate
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_longPressController.isCompleted) {
      _longPressController.reverse();
    }
    setState(() => _isLongPressing = false);
  }

  void _handleLongPressCancel() {
    _longPressController.reverse();
    setState(() => _isLongPressing = false);
  }

  void _removePlayer(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _players[index].controller.dispose();
      _players.removeAt(index);
    });
  }

  Color _getPlayerColor(int index) {
    final colors = [
      // HIGH CONTRAST on hot pink
      const Color(0xFFFFD60A), // Bright yellow (complementary)
      const Color(0xFF06FFA5), // Bright mint green
      const Color(0xFF00D9FF), // Neon cyan
      const Color(0xFF4CC9F0), // Bright sky blue
      const Color(0xFF7209B7), // Deep purple
      const Color(0xFFB5FF00), // Lime green
      const Color(0xFFFFA500), // Bright orange
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFF9D4EDD), // Lavender purple
      const Color(0xFFFFE066), // Golden yellow
      const Color(0xFF00F5A0), // Aqua green
    ];
    return colors[index % colors.length];
  }

  void _cycleMode() {
    HapticFeedback.selectionClick();
    setState(() {
      final currentIndex = GameConstants.modes.indexOf(_selectedMode);
      _selectedMode = GameConstants.modes[(currentIndex + 1) % GameConstants.modes.length];
    });
  }

  void _startGame() {
    // Heavy haptic when game starts
    HapticFeedback.heavyImpact();

    // Auto-name unnamed players
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].controller.text.trim().isEmpty) {
        _players[i].controller.text = 'Player ${i + 1}';
      }
    }

    final players = _players
        .map((p) => Player(
      name: p.controller.text.trim(),
      color: p.color,
    ))
        .toList();

    if (players.length < 2) {
      _showMessage('Need at least 2 players!');
      _longPressController.reverse();
      setState(() => _isLongPressing = false);
      return;
    }

    final gameState = GameState(
      players: players,
      selectedMode: _selectedMode,
      timerDuration: _timerDuration,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(gameState: gameState)),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF1C1C1E),
        margin: const EdgeInsets.only(top: 60, left: 20, right: 20),
        dismissDirection: DismissDirection.up,
      ),
    );
  }

  Future<bool> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Exit setup?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Exit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _confirmExit();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFF006E), // Deep navy blue
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: _handleTapDown,
          onLongPressStart: _handleLongPressStart,
          onLongPressEnd: _handleLongPressEnd,
          onLongPressCancel: _handleLongPressCancel,
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Text(
                      'Tap anywhere to add players',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFDF5), // Warm off-white
                      ),
                    ),
                  ),
                ),

                if (_players.isEmpty)
                  Center(
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'TOO SLOW',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFFFD60A), // Warm off-white (softer than pure white)
                              height: 0.9,
                              letterSpacing: -2,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'GAME TIMER',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFFDF5), // Bright yellow accent
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ..._players.asMap().entries.map((entry) {
                  final index = entry.key;
                  final player = entry.value;
                  return Positioned(
                    left: player.absolutePosition.dx,
                    top: player.absolutePosition.dy,
                    child: GestureDetector(
                      onTap: () {},
                      behavior: HitTestBehavior.opaque,
                      child: StickFigurePlayer(
                        color: player.color,
                        nameController: player.controller,
                        showingInput: player.showingInput,
                        playerNumber: index + 1, // ADD THIS
                        showOrderControls: _players.length > 1, // ADD THIS
                        canMoveUp: index > 0, // ADD THIS
                        canMoveDown: index < _players.length - 1, // ADD THIS
                        onMoveUp: () => _movePlayerUp(index), // ADD THIS
                        onMoveDown: () => _movePlayerDown(index), // ADD THIS
                        onDelete: () => _removePlayer(index),
                        onInputToggle: (showing) {
                          // When closing input, auto-name if empty
                          if (!showing && player.controller.text.trim().isEmpty) {
                            player.controller.text = 'Player ${index + 1}';
                          }
                          setState(() => player.showingInput = showing);
                        },
                      ),
                    ),
                  );
                }),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _cycleMode,
                          child: Column(
                            children: [
                              Text(
                                _selectedMode,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFFDF5), // Warm off-white
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                width: 80,
                                color: const Color(0xFFFFD60A), // Yellow accent
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_timerDuration > 5) {
                                        setState(() => _timerDuration -= 5);
                                      }
                                    },
                                      icon: const Icon(Icons.remove, color: Color(0xFFFFFDF5)) // White
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${_timerDuration}s',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFFFFFF), // White
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (_timerDuration < 30) {
                                        setState(() => _timerDuration += 5);
                                      }
                                    },
                                    icon: const Icon(Icons.add, color: Color(0xFFFFFDF5)),
                                  ),
                                ],
                              ),
                              if (_isLongPressing)
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: _longPressController.value,
                                    strokeWidth: 3,
                                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB703)), // Amber flame
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

// Animated pulsing text
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: const Text(
                                'Long press here to start',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFFFDF5), // Warm off-white
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerData {
  final TextEditingController controller;
  final Color color;
  final Offset absolutePosition;
  final Offset position;
  bool showingInput;

  PlayerData({
    required this.controller,
    required this.color,
    required this.absolutePosition,
    required this.position,
    this.showingInput = false,
  });
}