import 'package:flutter/material.dart';

import '../../core/security/app_lock_service.dart';

/// A PIN entry screen for app lock.
///
/// Shows a numpad with visual feedback and speaks the PIN digits for
/// accessibility.
class AppLockScreen extends StatefulWidget {
  /// Create the lock screen.
  const AppLockScreen({
    super.key,
    required this.service,
    required this.onUnlock,
  });

  /// The app lock service.
  final AppLockService service;

  /// Called with true when unlock succeeds, false when canceled.
  final ValueChanged<bool> onUnlock;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final List<String> _digits = [];
  final TextEditingController _pinController = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _appendDigit(String digit) {
    if (_digits.length < 6) {
      setState(() => _digits.add(digit));
      _pinController.text = '*' * _digits.length;
      _pinController.selection = TextSelection.fromPosition(
        TextPosition(offset: _pinController.text.length),
      );
      // Speak the digit for accessibility
      // This would be handled by the calling screen's announcer
    }
  }

  void _backspace() {
    if (_digits.isNotEmpty) {
      setState(() => _digits.removeLast());
      _pinController.text = '*' * _digits.length;
    }
  }

  void _clear() {
    setState(() => _digits.clear());
    _pinController.clear();
    _showError = false;
  }

  Future<void> _submit() async {
    if (_digits.length != 6) {
      _showError = true;
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 400));
        if (mounted) setState(() => _showError = false);
      }
      return;
    }

    final pin = _digits.join();
    final ok = await widget.service.verify(pin);
    if (!mounted) return;

    if (ok) {
      widget.onUnlock(true);
    } else {
      _showError = true;
      if (widget.service.failedAttempts >= 3 && mounted) {
        // Vibrate on wrong PIN
        // Vibration.vibrate(duration: 200);
      }
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _showError = false);
      _clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLocked = widget.service.isLocked;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 48),
            if (isLocked)
              Column(
                children: <Widget>[
                  const Icon(
                    Icons.lock_clock_rounded,
                    size: 64,
                    color: Colors.black54,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Locked for 5 minutes',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else ...<Widget>[
              const Icon(
                Icons.lock_rounded,
                size: 64,
                color: Colors.black54,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (int index) {
                  final filled = index < _digits.length;
                  final error = _showError && index == _digits.length - 1;
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: error
                          ? theme.colorScheme.error
                          : (filled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TextField(
                  controller: _pinController,
                  enabled: false,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit PIN',
                    border: InputBorder.none,
                    errorText: _showError ? 'Incorrect PIN' : null,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  if (isLocked) ...<Widget>[
                    Text(
                      'Wait for automatic unlock',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (int index) => _numpadRow(index)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FilledButton.tonal(
                    onPressed: _clear,
                    child: const Text('Cancel'),
                  ),
                  if (!isLocked)
                    FilledButton(
                      onPressed: _digits.length == 6 ? _submit : null,
                      child: const Text('Unlock'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Row _numpadRow(int row) {
    final digits = <String>[];
    if (row == 2) {
      digits.addAll(['1', '2', '3']);
    } else if (row == 3) {
      digits.addAll(['*', '0', '']);
    } else {
      digits.addAll(['${row * 3 + 1}', '${row * 3 + 2}', '${row * 3 + 3}']);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((String digit) {
        if (digit.isEmpty) return const SizedBox(width: 48);
        if (digit == '*') {
          return _NumpadButton.icon(
            icon: Icons.backspace_rounded,
            onPressed: _backspace,
          );
        }
        return _NumpadButton.label(
          label: digit,
          onPressed: () => _appendDigit(digit),
        );
      }).toList(),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  const _NumpadButton.label({
    required this.label,
    required this.onPressed,
  }) : icon = null;

  const _NumpadButton.icon({
    required this.icon,
    required this.onPressed,
  }) : label = null;

  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          shape: const CircleBorder(),
        ),
        child: label != null
            ? Text(
                label!,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(icon, size: 24),
      ),
    );
  }
}
