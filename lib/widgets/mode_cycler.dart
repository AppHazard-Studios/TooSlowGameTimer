import 'package:flutter/material.dart';

class ModeCycler extends StatelessWidget {
  final List<String> modes;
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  const ModeCycler({
    super.key,
    required this.modes,
    required this.selectedMode,
    required this.onModeChanged,
  });

  void _cycleMode() {
    final currentIndex = modes.indexOf(selectedMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    onModeChanged(modes[nextIndex]);
  }

  String _getModeEmoji() {
    switch (selectedMode) {
      case 'Chill': return '😌';
      case 'Banter': return '😏';
      case 'Savage': return '🔥';
      case 'Pirate': return '🏴‍☠️';
      case 'Corporate': return '💼';
      default: return '😎';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _cycleMode,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFF6B35), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              _getModeEmoji(),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                  Text(
                    selectedMode,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B35), size: 28),
          ],
        ),
      ),
    );
  }
}