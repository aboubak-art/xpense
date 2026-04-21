import 'package:flutter/material.dart';

import 'package:xpense/core/haptics/haptic_service.dart';

/// Callback signature for keypad actions.
typedef KeypadValueCallback = void Function(String value);

/// A custom numeric keypad with 56dp touch targets, haptic feedback,
/// and scale-bounce animations on digit entry.
class CustomKeypad extends StatelessWidget {
  const CustomKeypad({
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
    required this.onDone,
    super.key,
  });

  final KeypadValueCallback onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        children: [
          _buildRow(['1', '2', '3'], colorScheme),
          _buildRow(['4', '5', '6'], colorScheme),
          _buildRow(['7', '8', '9'], colorScheme),
          _buildBottomRow(colorScheme),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> digits, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _DigitKey(
        digit: d,
        onTap: () {
          HapticService.lightImpact();
          onDigit(d);
        },
        colorScheme: colorScheme,
      ),).toList(),
    );
  }

  Widget _buildBottomRow(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ActionKey(
          icon: Icons.backspace_outlined,
          onTap: () {
            HapticService.lightImpact();
            onBackspace();
          },
          colorScheme: colorScheme,
        ),
        _DigitKey(
          digit: '0',
          onTap: () {
            HapticService.lightImpact();
            onDigit('0');
          },
          colorScheme: colorScheme,
        ),
        _ActionKey(
          icon: Icons.check,
          onTap: () {
            HapticService.mediumImpact();
            onDone();
          },
          colorScheme: colorScheme,
          isPrimary: true,
        ),
      ],
    );
  }
}

class _DigitKey extends StatefulWidget {
  const _DigitKey({
    required this.digit,
    required this.onTap,
    required this.colorScheme,
  });

  final String digit;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  @override
  State<_DigitKey> createState() => _DigitKeyState();
}

class _DigitKeyState extends State<_DigitKey>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final _scale = Tween<double>(begin: 1, end: 0.9).animate(
    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 56,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Text(
              widget.digit,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: widget.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  const _ActionKey({
    required this.icon,
    required this.onTap,
    required this.colorScheme,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.08);
    final fgColor = isPrimary
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 56,
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: fgColor, size: 24),
          ),
        ),
      ),
    );
  }
}
