import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/player.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import '../widgets/stick_figure_player.dart';
import '../services/preferences_service.dart';
import 'game_screen.dart';

enum PoseType {
  defaultPose,
  handsOnHips,
  oneArmWaving,
  armsCrossed,
  pointingUp,
  shrugging,
}

enum AnimationType {
  bobbing,
  swaying,
  breathing,
  bouncing,
}

enum AccessoryType {
  none,
  partyHat,
  topHat,
  cap,
  glasses,
}

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
  bool _showingSettings = false;
  String _currentTtsProvider = 'sherpa';

  late AnimationController _longPressController;
  late AnimationController _pulseController;
  late AnimationController _settingsOverlayController;
  late AnimationController _overlayController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _settingsOverlayAnimation;
  late Animation<double> _overlayAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentTtsProvider = PreferencesService().getTtsProvider();

    _longPressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
      if (_longPressController.isCompleted && mounted) {
        _startGame();
      }
      setState(() {});
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _settingsOverlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _settingsOverlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _settingsOverlayController, curve: Curves.easeOut),
    );

    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _overlayAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _overlayController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_longPressController.value > 0) {
      _longPressController.reset();
      setState(() => _isLongPressing = false);
    }
  }

  @override
  void dispose() {
    _longPressController.dispose();
    _pulseController.dispose();
    _settingsOverlayController.dispose();
    _overlayController.dispose();
    for (var player in _players) {
      player.controller.dispose();
      player.positionController.dispose();
    }
    super.dispose();
  }

  void _toggleSettings() {
    HapticFeedback.lightImpact();
    setState(() {
      _showingSettings = !_showingSettings;
      if (_showingSettings) {
        _settingsOverlayController.forward();
      } else {
        _settingsOverlayController.reverse();
      }
    });
  }

  void _handleSettingsOverlayTap() {
    HapticFeedback.lightImpact();
    _settingsOverlayController.reverse().then((_) {
      if (mounted) {
        setState(() => _showingSettings = false);
      }
    });
  }

  Future<void> _setTtsProvider(String provider) async {
    HapticFeedback.selectionClick();
    await PreferencesService().setTtsProvider(provider);
    setState(() => _currentTtsProvider = provider);
  }

  void _movePlayerUp(int index) {
    if (index == 0) return;

    HapticFeedback.selectionClick();
    setState(() {
      final temp = _players[index];
      _players[index] = _players[index - 1];
      _players[index - 1] = temp;
    });
  }

  void _movePlayerDown(int index) {
    if (index == _players.length - 1) return;

    HapticFeedback.selectionClick();
    setState(() {
      final temp = _players[index];
      _players[index] = _players[index + 1];
      _players[index + 1] = temp;
    });
  }

  void _handleTapDown(TapDownDetails details) {
    if (_showingSettings) return;

    final size = MediaQuery.of(context).size;
    double tapX = details.localPosition.dx;
    double tapY = details.localPosition.dy;

    if (tapY > size.height - 240) {
      if (!_isLongPressing) {
        HapticFeedback.heavyImpact();
        setState(() => _isLongPressing = true);
        _longPressController.forward();
      }
      return;
    }

    if (_isLongPressing) return;

    if (_players.isNotEmpty && _players.last.showingInput && _players.last.controller.text.trim().isEmpty) {
      _showMessage('Name the current player first!');
      HapticFeedback.mediumImpact();
      return;
    }

    for (int i = 0; i < _players.length; i++) {
      if (_players[i].showingInput && _players[i].controller.text.trim().isEmpty) {
        _players[i].controller.text = 'Player ${i + 1}';
      }
      _players[i].showingInput = false;
    }

    _overlayController.reverse();
    FocusScope.of(context).unfocus();

    if (tapY < 50) tapY = 50 + 20;
    if (tapY > size.height - 230 - 20) tapY = size.height - 250;

    final figureHeight = 170.0;
    final figureWidth = 140.0;

    double widgetLeft = tapX - 70;
    double widgetTop = tapY - 12;

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

    HapticFeedback.mediumImpact();

    // Create position animation controller
    final posController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final padding = MediaQuery.of(context).padding;
    final centerX = size.width / 2 - 70;
    final centerY = size.height / 2 - 85;

    // Animate from tap position to center
    final posAnimation = Tween<Offset>(
      begin: Offset(widgetLeft, widgetTop + padding.top),
      end: Offset(centerX, centerY),
    ).animate(CurvedAnimation(
      parent: posController,
      curve: Curves.easeOut,
    ));

    // Generate random visual variations
    final random = Random();
    final headScale = 0.8 + random.nextDouble() * 0.4;
    final torsoScale = 0.8 + random.nextDouble() * 0.5;
    final armScale = 0.85 + random.nextDouble() * 0.3;
    final legScale = 0.85 + random.nextDouble() * 0.3;

    // 20% chance for accessory
    final accessoryType = random.nextDouble() < 0.2
        ? AccessoryType.values[1 + random.nextInt(AccessoryType.values.length - 1)]
        : AccessoryType.none;

    // Random pose and animation
    final poseType = PoseType.values[random.nextInt(PoseType.values.length)];
    final animationType = AnimationType.values[random.nextInt(AnimationType.values.length)];

    setState(() {
      _players.add(PlayerData(
        controller: TextEditingController(),
        color: _getPlayerColor(_players.length),
        absolutePosition: Offset(widgetLeft, widgetTop + padding.top),
        position: Offset(relativeX, relativeY),
        showingInput: true,
        positionController: posController,
        positionAnimation: posAnimation,
        headScale: headScale,
        torsoScale: torsoScale,
        armScale: armScale,
        legScale: legScale,
        accessoryType: accessoryType,
        poseType: poseType,
        animationType: animationType,
      ));
    });

    // Start animations
    posController.forward();
    _overlayController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isLongPressing) {
      if (!_longPressController.isCompleted) {
        _longPressController.reverse();
      }
      setState(() => _isLongPressing = false);
    }
  }

  void _handleTapCancel() {
    if (_isLongPressing) {
      _longPressController.reverse();
      setState(() => _isLongPressing = false);
    }
  }

  void _handleOverlayTap() {
    int? activeIndex;
    for (int i = 0; i < _players.length; i++) {
      if (_players[i].showingInput) {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex != null && _players[activeIndex].controller.text.trim().isEmpty) {
      _showMessage('Name the current player first!');
      HapticFeedback.mediumImpact();
      return;
    }

    _confirmPlayer(activeIndex);
  }

  void _confirmPlayer(int? index) {
    if (index == null) return;

    final player = _players[index];
    if (player.controller.text.trim().isEmpty) {
      _showMessage('Name the current player first!');
      return;
    }

    FocusScope.of(context).unfocus();

    // First change to saved name display
    setState(() => player.showingInput = false);

    // Then animate position back after UI updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      player.positionController.reverse();
      _overlayController.reverse();
    });
  }

  void _removePlayer(int index) {
    HapticFeedback.mediumImpact();

    final player = _players[index];

    // If this was the naming player, close overlay
    if (player.showingInput) {
      _overlayController.reverse();
    }

    setState(() {
      player.controller.dispose();
      player.positionController.dispose();
      _players.removeAt(index);
    });
  }

  Color _getPlayerColor(int index) {
    final colors = [
      const Color(0xFFFFD60A),
      const Color(0xFF06FFA5),
      const Color(0xFF00D9FF),
      const Color(0xFF4CC9F0),
      const Color(0xFF7209B7),
      const Color(0xFFB5FF00),
      const Color(0xFFFFA500),
      const Color(0xFF00FFFF),
      const Color(0xFF9D4EDD),
      const Color(0xFFFFE066),
      const Color(0xFF00F5A0),
    ];
    return colors[index % colors.length];
  }

  void _cycleMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      final currentIndex = GameConstants.modes.indexOf(_selectedMode);
      _selectedMode = GameConstants.modes[(currentIndex + 1) % GameConstants.modes.length];
    });
  }

  void _startGame() {
    HapticFeedback.heavyImpact();

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
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context, false);
                      },
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
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.pop(context, true);
                      },
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
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    // Title centering: empty screen = center, has players = top
    final shouldBeAtCenter = _players.isEmpty;

    final safeHeight = size.height - padding.top - padding.bottom;
    final titleCenterTop = padding.top + (safeHeight * 0.35);

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
        backgroundColor: const Color(0xFFFF006E),
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (isKeyboardOpen || _showingSettings) ? null : _handleTapDown,
          onTapUp: (isKeyboardOpen || _showingSettings) ? null : _handleTapUp,
          onTapCancel: (isKeyboardOpen || _showingSettings) ? null : _handleTapCancel,
          child: Stack(
            children: [
              // Layer 1: Instruction text
              Positioned(
                top: 20 + padding.top,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    'Tap anywhere to add players',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFDF5),
                    ),
                  ),
                ),
              ),

              // Layer 2: Bottom controls
              Positioned(
                bottom: padding.bottom,
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
                                color: Color(0xFFFFFDF5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              width: 80,
                              color: const Color(0xFFFFD60A),
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
                                      HapticFeedback.selectionClick();
                                      setState(() => _timerDuration -= 5);
                                    }
                                  },
                                  icon: const Icon(Icons.remove, color: Color(0xFFFFFDF5)),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    '${_timerDuration}s',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    if (_timerDuration < 30) {
                                      HapticFeedback.selectionClick();
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
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB703)),
                                  backgroundColor: Colors.white24,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                                color: Color(0xFFFFFDF5),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Layer 3: Players NOT being named
              ..._players.asMap().entries.where((entry) => !entry.value.showingInput).map((entry) {
                final index = entry.key;
                final player = entry.value;

                return AnimatedBuilder(
                  animation: player.positionAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: player.positionAnimation.value.dx,
                      top: player.positionAnimation.value.dy,
                      child: GestureDetector(
                        onTap: () {},
                        onTapDown: (_) {},
                        onTapUp: (_) {},
                        behavior: HitTestBehavior.opaque,
                        child: StickFigurePlayer(
                          color: player.color,
                          nameController: player.controller,
                          showingInput: false,
                          playerNumber: index + 1,
                          showOrderControls: _players.length > 1,
                          canMoveUp: index > 0,
                          canMoveDown: index < _players.length - 1,
                          onMoveUp: () => _movePlayerUp(index),
                          onMoveDown: () => _movePlayerDown(index),
                          onDelete: () => _removePlayer(index),
                          onInputToggle: (showing) {
                            if (showing) {
                              setState(() => player.showingInput = true);
                            }
                          },
                          headScale: player.headScale,
                          torsoScale: player.torsoScale,
                          armScale: player.armScale,
                          legScale: player.legScale,
                          accessoryType: player.accessoryType,
                          poseType: player.poseType,
                          animationType: player.animationType,
                        ),
                      ),
                    );
                  },
                );
              }),

              // Layer 4: Settings cog (under overlays, non-clickable during naming)
              Positioned(
                top: 20 + padding.top,
                right: 20,
                child: IgnorePointer(
                  ignoring: _overlayController.value > 0,
                  child: GestureDetector(
                    onTap: _toggleSettings,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.settings,
                        size: 28,
                        color: Color(0xFFFFFDF5),
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 5: Naming overlay (animated fade)
              if (_overlayController.value > 0)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleOverlayTap,
                    child: AnimatedBuilder(
                      animation: _overlayAnimation,
                      builder: (context, child) {
                        return Container(
                          color: Color(0xFF000000).withOpacity(0.5 * _overlayAnimation.value),
                        );
                      },
                    ),
                  ),
                ),

              // Layer 6: Player being named (ABOVE overlay)
              ..._players.asMap().entries.where((entry) => entry.value.showingInput).map((entry) {
                final index = entry.key;
                final player = entry.value;

                return AnimatedBuilder(
                  animation: player.positionAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: player.positionAnimation.value.dx,
                      top: player.positionAnimation.value.dy,
                      child: GestureDetector(
                        onTap: () {},
                        onTapDown: (_) {},
                        onTapUp: (_) {},
                        behavior: HitTestBehavior.opaque,
                        child: StickFigurePlayer(
                          color: player.color,
                          nameController: player.controller,
                          showingInput: true,
                          playerNumber: index + 1,
                          showOrderControls: false,
                          canMoveUp: false,
                          canMoveDown: false,
                          onMoveUp: () {},
                          onMoveDown: () {},
                          onDelete: _players.length == 1 ? null : () => _removePlayer(index),
                          onInputToggle: (showing) {
                            if (!showing) {
                              _confirmPlayer(index);
                            }
                          },
                          headScale: player.headScale,
                          torsoScale: player.torsoScale,
                          armScale: player.armScale,
                          legScale: player.legScale,
                          accessoryType: player.accessoryType,
                          poseType: player.poseType,
                          animationType: player.animationType,
                        ),
                      ),
                    );
                  },
                );
              }),

              // Layer 7: Settings overlay (animated, tappable to close)
              if (_showingSettings || _settingsOverlayController.value > 0)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleSettingsOverlayTap,
                    child: AnimatedBuilder(
                      animation: _settingsOverlayAnimation,
                      builder: (context, child) {
                        return Container(
                          color: Color(0xFF000000).withOpacity(0.5 * _settingsOverlayAnimation.value),
                        );
                      },
                    ),
                  ),
                ),

              // Layer 8: Title (animated position)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                top: shouldBeAtCenter ? titleCenterTop : 60 + padding.top,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: shouldBeAtCenter ? 64 : 32,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD60A),
                            height: 0.9,
                            letterSpacing: -2,
                          ),
                          child: const Text('TOO SLOW'),
                        ),
                        SizedBox(height: shouldBeAtCenter ? 8 : 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeInOut,
                          style: TextStyle(
                            fontSize: shouldBeAtCenter ? 24 : 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFFDF5),
                          ),
                          child: const Text('GAME TIMER'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Layer 9: Settings dropdown (above overlay, blocks inner taps only)
              if (_showingSettings)
                Positioned(
                  top: 58 + padding.top,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 1,
                            color: Colors.white.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Low Performance Mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'If your device struggles with voice quality, enable this to use a simpler text-to-speech system.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => _setTtsProvider('sherpa'),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: _currentTtsProvider == 'sherpa'
                                        ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFD60A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Off (Recommended)',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _setTtsProvider('flutter'),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: _currentTtsProvider == 'flutter'
                                        ? Center(
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFD60A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'On',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white,
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
            ],
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
  final AnimationController positionController;
  final Animation<Offset> positionAnimation;

  // Visual variations
  final double headScale;
  final double torsoScale;
  final double armScale;
  final double legScale;
  final AccessoryType accessoryType;
  final PoseType poseType;
  final AnimationType animationType;

  PlayerData({
    required this.controller,
    required this.color,
    required this.absolutePosition,
    required this.position,
    this.showingInput = false,
    required this.positionController,
    required this.positionAnimation,
    required this.headScale,
    required this.torsoScale,
    required this.armScale,
    required this.legScale,
    required this.accessoryType,
    required this.poseType,
    required this.animationType,
  });
}