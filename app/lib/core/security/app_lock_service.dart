import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Simple PIN-based app lock.
class AppLockService {
  /// Create the lock. Must call [load] before use.
  AppLockService(this._prefs);

  final SharedPreferences _prefs;

  static const String _kPinHash = 'app_lock_pin_hash';
  static const String _kEnabled = 'app_lock_enabled';
  static const String _kAttempts = 'app_lock_attempts';
  static const String _kLockedUntil = 'app_lock_locked_until';

  String? _pinHash;
  bool _enabled = false;
  int _failedAttempts = 0;
  int? _lockedUntil;

  bool get isEnabled => _enabled;

  bool get isLocked {
    if (!_enabled) return false;
    if (_lockedUntil == null) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 < _lockedUntil!;
  }

  int get failedAttempts => _failedAttempts;

  Future<void> load() async {
    _enabled = _prefs.getBool(_kEnabled) ?? false;
    _pinHash = _prefs.getString(_kPinHash);
    _failedAttempts = _prefs.getInt(_kAttempts) ?? 0;
    final lockedMs = _prefs.getInt(_kLockedUntil);
    _lockedUntil = lockedMs != null && lockedMs > 0 ? lockedMs ~/ 1000 : null;
  }

  Future<void> save() async {
    await _prefs.setBool(_kEnabled, _enabled);
    if (_pinHash != null) {
      await _prefs.setString(_kPinHash, _pinHash!);
    } else {
      await _prefs.remove(_kPinHash);
    }
    await _prefs.setInt(_kAttempts, _failedAttempts);
    if (_lockedUntil != null) {
      await _prefs.setInt(_kLockedUntil, _lockedUntil! * 1000);
    } else {
      await _prefs.remove(_kLockedUntil);
    }
  }

  static String hashPin(String pin, {int iterations = 10000}) {
    List<int> data = utf8.encode(pin);
    for (var i = 0; i < iterations; i++) {
      final digest = sha256.convert(data);
      data = digest.bytes;
    }
    return sha256.convert(data).toString();
  }

  Future<void> enable(String pin) async {
    _pinHash = hashPin(pin);
    _enabled = true;
    _failedAttempts = 0;
    _lockedUntil = null;
    await save();
  }

  Future<void> disable() async {
    _enabled = false;
    _pinHash = null;
    _failedAttempts = 0;
    _lockedUntil = null;
    await save();
  }

  Future<bool> verify(String pin) async {
    if (!_enabled || _pinHash == null) return true;

    if (isLocked) {
      return false;
    }

    final hash = hashPin(pin);
    if (hash == _pinHash) {
      _failedAttempts = 0;
      _lockedUntil = null;
      await save();
      return true;
    }

    _failedAttempts++;
    if (_failedAttempts >= 5) {
      _lockedUntil = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300;
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 500);
      }
    }
    await save();
    return false;
  }

  Future<void> clear() async {
    _enabled = false;
    _pinHash = null;
    _failedAttempts = 0;
    _lockedUntil = null;
    await save();
  }
}
