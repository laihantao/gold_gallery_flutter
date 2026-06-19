import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _pinHashKey = 'app_pin_hash';
  static const _pinEnabledKey = 'pin_enabled';
  static const _attemptsKey = 'pin_attempts';
  static const _secQIndexKey = 'sec_q_index';
  static const _secAHashKey = 'sec_answer_hash';

  static const int maxAttempts = 5;

  static const List<String> securityQuestions = [
    'What is the name of your first pet?',
    'What was the name of your primary school?',
    "What is your mother's maiden name?",
    'What was the name of your childhood best friend?',
    'What was your first job?',
  ];

  // ── PIN enable/disable ────────────────────────────────────────────────────

  static Future<bool> isPinEnabled() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinHashKey, _hash(pin));
    await prefs.setBool(_pinEnabledKey, true);
    await prefs.setInt(_attemptsKey, 0);
  }

  static Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_pinHashKey);
    return stored != null && stored == _hash(pin);
  }

  static Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinHashKey);
    await prefs.setBool(_pinEnabledKey, false);
    await prefs.remove(_attemptsKey);
    await prefs.remove(_secQIndexKey);
    await prefs.remove(_secAHashKey);
  }

  // ── Attempt tracking ──────────────────────────────────────────────────────

  static Future<int> getAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_attemptsKey) ?? 0;
  }

  static Future<int> incrementAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final next = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    await prefs.setInt(_attemptsKey, next);
    return next;
  }

  static Future<void> resetAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_attemptsKey, 0);
  }

  // ── Security Q&A ──────────────────────────────────────────────────────────

  static Future<void> setSecurityQA(int questionIndex, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_secQIndexKey, questionIndex);
    await prefs.setString(_secAHashKey, _hash(answer.trim().toLowerCase()));
  }

  static Future<String?> getSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_secQIndexKey);
    if (idx == null || idx < 0 || idx >= securityQuestions.length) return null;
    return securityQuestions[idx];
  }

  static Future<bool> verifySecurityAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_secAHashKey);
    return stored != null &&
        stored == _hash(answer.trim().toLowerCase());
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static String _hash(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
