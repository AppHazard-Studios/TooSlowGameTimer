import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/game_state.dart';
import '../services/tts_service.dart';
import '../widgets/hard_line_timer.dart';
import 'package:flutter/services.dart';

class GameScreen extends StatefulWidget {
  final GameState gameState;

  const GameScreen({super.key, required this.gameState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TtsService _tts = TtsService();
  final math.Random _random = math.Random();
  bool _waitingForNextPlayer = false;
  int _timerKey = 0;
  WipeDirection _currentDirection = WipeDirection.down;

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  WipeDirection _getNewRandomDirection() {
    final directions = [
      WipeDirection.down,
      WipeDirection.up,
      WipeDirection.left,
      WipeDirection.right,
    ];

    // Remove current direction to ensure variety
    directions.remove(_currentDirection);

    // Pick random from remaining
    return directions[_random.nextInt(directions.length)];
  }

  void _handleTap() {
    HapticFeedback.mediumImpact(); // Changed from lightImpact

    if (_waitingForNextPlayer) {
      setState(() {
        _waitingForNextPlayer = false;
        widget.gameState.nextPlayer();
      });
    } else {
      setState(() {
        _waitingForNextPlayer = true;
        _timerKey++;
        _currentDirection = _getNewRandomDirection();
      });
    }
  }

  void _onTimerComplete() {
    HapticFeedback.heavyImpact(); // Changed from mediumImpact

    final nextPlayerIndex = (widget.gameState.currentPlayerIndex + 1) % widget.gameState.players.length;
    final nextPlayer = widget.gameState.players[nextPlayerIndex];
    _tts.speakRoast(nextPlayer.name, widget.gameState.selectedMode);

    setState(() {
      _timerKey++;
      _currentDirection = _getNewRandomDirection();
    });
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
                'End game?',
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
                      onTap: () {
                        HapticFeedback.lightImpact(); // Added
                        Navigator.pop(context, false);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Keep Playing',
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
                      onTap: () {
                        HapticFeedback.mediumImpact(); // Added
                        Navigator.pop(context, true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'End Game',
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
    final currentPlayer = widget.gameState.currentPlayer;
    final nextPlayerIndex = (widget.gameState.currentPlayerIndex + 1) % widget.gameState.players.length;
    final nextPlayer = widget.gameState.players[nextPlayerIndex];
    final playerAfterNextIndex = (nextPlayerIndex + 1) % widget.gameState.players.length;
    final playerAfterNext = widget.gameState.players[playerAfterNextIndex];

    final displayName = _waitingForNextPlayer ? nextPlayer.name : currentPlayer.name;
    final instruction = _waitingForNextPlayer ? 'TAP TO START TURN' : 'TAP TO END TURN';
    final backgroundColor = _waitingForNextPlayer ? nextPlayer.color : currentPlayer.color;

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
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleTap,
          child: Stack(
            children: [
              if (_waitingForNextPlayer)
                HardLineTimer(
                  key: ValueKey(_timerKey),
                  durationSeconds: widget.gameState.timerDuration,
                  startColor: nextPlayer.color,
                  endColor: playerAfterNext.color,
                  direction: _currentDirection,
                  onComplete: _onTimerComplete,
                )
              else
                Container(color: backgroundColor),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width - 40,
                              ),
                              child: Text(
                                displayName.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 80,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1,
                                  letterSpacing: -2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            instruction,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.85),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Transform.rotate(
                        angle: 3.14159,
                        child: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width - 40,
                                ),
                                child: Text(
                                  displayName.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1,
                                    letterSpacing: -2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              instruction,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}