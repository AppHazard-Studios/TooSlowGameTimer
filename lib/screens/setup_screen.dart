import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
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

class _SetupScreenState extends State<SetupScreen> with SingleTickerProviderStateMixin, RouteAware {
  final List<PlayerData> _players = [];
  String _selectedMode = GameConstants.modes[1];
  int _timerDuration = GameConstants.defaultTimerSeconds;
  bool _isLongPressing = false;
  late AnimationController _longPressController;

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
    for (var player in _players) {
      player.controller.dispose();
    }
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isLongPressing) return;

    final size = MediaQuery.of(context).size;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    // Don't add if tapping controls (bottom 220px to be safe)
    if (tapY > size.height - 220) return;
    if (tapY < 100) return;

    // Don't add new player if current player hasn't been named
    if (_players.isNotEmpty && _players.last.controller.text.trim().isEmpty) {
      _showMessage('Name the current player first!');
      return;
    }

    // Close all existing name inputs
    for (var player in _players) {
      player.showingInput = false;
    }
    FocusScope.of(context).unfocus();

    final widgetLeft = tapX - 70;
    final widgetTop = tapY - 12;

    final relativeX = tapX / size.width;
    final relativeY = (tapY - 100) / (size.height - 320);

    if (relativeX < 0.15 || relativeX > 0.85 || relativeY < 0.1 || relativeY > 0.75) {
      return;
    }

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

    // Only allow long press on bottom area
    if (position.dy > size.height - 200) {
      setState(() => _isLongPressing = true);
      _longPressController.forward();
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
    setState(() {
      _players[index].controller.dispose();
      _players.removeAt(index);
    });
  }

  Color _getPlayerColor(int index) {
    final colors = [
      const Color(0xFFFF6B35),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFD60A),
      const Color(0xFFFF006E),
      const Color(0xFF8338EC),
      const Color(0xFF06FFA5),
      const Color(0xFFFF9F1C),
      const Color(0xFF3A86FF),
      const Color(0xFFFB5607),
      const Color(0xFF00F5FF),
    ];
    return colors[index % colors.length];
  }

  void _cycleMode() {
    setState(() {
      final currentIndex = GameConstants.modes.indexOf(_selectedMode);
      _selectedMode = GameConstants.modes[(currentIndex + 1) % GameConstants.modes.length];
    });
  }

  void _startGame() {
    final players = _players
        .where((p) => p.controller.text.trim().isNotEmpty)
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
        backgroundColor: const Color(0xFFFF9F1C),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600, // Changed from w500
                    color: Colors.white, // Changed from white70
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
                              color: Colors.black,
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
                              color: Colors.white,
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
                        onDelete: () => _removePlayer(index),
                        onInputToggle: (showing) {
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
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                width: 80,
                                color: Colors.black,
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
                              // Background layer - always present
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (_timerDuration > 5) {
                                        setState(() => _timerDuration -= 5);
                                      }
                                    },
                                    icon: const Icon(Icons.remove, color: Colors.black),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${_timerDuration}s',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (_timerDuration < 30) {
                                        setState(() => _timerDuration += 5);
                                      }
                                    },
                                    icon: const Icon(Icons.add, color: Colors.black),
                                  ),
                                ],
                              ),
                              // Progress overlay
                              if (_isLongPressing)
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: _longPressController.value,
                                    strokeWidth: 3,
                                    valueColor: const AlwaysStoppedAnimation(Colors.black),
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        IgnorePointer(
                          child: const Text(
                            'Long press here to start',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
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