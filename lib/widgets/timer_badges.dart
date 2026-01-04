import 'package:flutter/material.dart';

class TimerBadges extends StatelessWidget {
  final int selectedDuration;
  final ValueChanged<int> onDurationChanged;

  const TimerBadges({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final durations = [5, 10, 15, 20, 30];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Timer',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF999999),
            ),
          ),
        ),
        Row(
          children: durations.map((duration) {
            final isSelected = duration == selectedDuration;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onDurationChanged(duration),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF6B35) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF6B35) : const Color(0xFFEEEEEE),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                          : null,
                    ),
                    child: Text(
                      '${duration}s',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}