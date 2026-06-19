import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

/// [mode] = 'create' (first-time setup) or 'change' (update existing PIN).
/// On completion, calls [onComplete] so the caller can navigate away.
class PinSetupPage extends StatefulWidget {
  final String mode;
  final VoidCallback onComplete;

  const PinSetupPage({
    super.key,
    required this.mode,
    required this.onComplete,
  });

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends State<PinSetupPage> {
  // Steps: 0=verify current (change mode only), 1=enter new PIN, 2=confirm, 3=security Q
  late int _step;
  String _currentEntry = '';
  String _newPin = '';
  bool _wrongCurrent = false;
  bool _mismatch = false;

  // Security question
  int _qIndex = 0;
  final TextEditingController _answerCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _step = widget.mode == 'change' ? 0 : 1;
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  AppTheme get _t =>
      context.read<ThemeNotifier>().currentTheme;

  // ── Numpad input ──────────────────────────────────────────────────────────

  void _onKey(String d) {
    if (_step == 3) return; // security Q step uses text field
    if (_currentEntry.length >= 4) return;
    setState(() {
      _currentEntry += d;
      _wrongCurrent = false;
      _mismatch = false;
    });
    if (_currentEntry.length == 4) _onComplete();
  }

  void _onDelete() {
    if (_currentEntry.isEmpty) return;
    setState(() => _currentEntry =
        _currentEntry.substring(0, _currentEntry.length - 1));
  }

  Future<void> _onComplete() async {
    switch (_step) {
      case 0: // verify current PIN
        final ok = await AuthService.verifyPin(_currentEntry);
        if (!mounted) return;
        if (ok) {
          setState(() {
            _step = 1;
            _currentEntry = '';
          });
        } else {
          setState(() {
            _wrongCurrent = true;
            _currentEntry = '';
          });
        }

      case 1: // enter new PIN
        setState(() {
          _newPin = _currentEntry;
          _currentEntry = '';
          _step = 2;
        });

      case 2: // confirm new PIN
        if (_currentEntry == _newPin) {
          setState(() {
            _step = 3;
            _currentEntry = '';
          });
        } else {
          setState(() {
            _mismatch = true;
            _currentEntry = '';
            _step = 1;
            _newPin = '';
          });
        }
    }
  }

  Future<void> _saveAll() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _t.error,
          content: const Text('Please enter an answer to the security question.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    await AuthService.setPin(_newPin);
    await AuthService.setSecurityQA(_qIndex, answer);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onComplete();
  }

  // ── UI helpers ─────────────────────────────────────────────────────────────

  String get _stepTitle {
    return switch (_step) {
      0 => 'Enter Current PIN',
      1 => widget.mode == 'change' ? 'Enter New PIN' : 'Create PIN',
      2 => 'Confirm PIN',
      _ => 'Security Question',
    };
  }

  String get _stepSubtitle {
    return switch (_step) {
      0 => 'Verify your identity before changing',
      1 => 'Choose a 4-digit PIN',
      2 => 'Re-enter to confirm',
      _ => 'Used to recover your PIN if forgotten',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      backgroundColor: t.primaryBg,
      appBar: AppBar(
        backgroundColor: t.headerBg,
        foregroundColor: t.inkDark,
        elevation: 0,
        title: Text(
          'App PIN Lock',
          style: TextStyle(
              color: t.inkDark, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: t.inkDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _step == 3 ? _buildSecurityStep(t) : _buildPinStep(t),
    );
  }

  // ── PIN step (0, 1, 2) ────────────────────────────────────────────────────

  Widget _buildPinStep(AppTheme t) {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Step indicator
        StepDots(current: _step == 0 ? 0 : _step - 1, total: 3, theme: t),
        const SizedBox(height: 32),

        // Title
        Text(_stepTitle,
            style: TextStyle(
                color: t.inkDark, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(_stepSubtitle,
            style: TextStyle(color: t.inkMid, fontSize: 13)),
        const SizedBox(height: 8),

        // Error messages
        if (_wrongCurrent)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('Wrong PIN, try again.',
                style: TextStyle(color: t.error, fontSize: 12)),
          ),
        if (_mismatch)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text("PINs don't match, start again.",
                style: TextStyle(color: t.error, fontSize: 12)),
          ),

        const SizedBox(height: 32),

        // 4-dot PIN indicator
        PinDots(entered: _currentEntry.length, theme: t),

        const Spacer(),

        // Numpad
        Numpad(onKey: _onKey, onDelete: _onDelete, theme: t),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── Security question step (step 3) ───────────────────────────────────────

  Widget _buildSecurityStep(AppTheme t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          StepDots(current: 2, total: 3, theme: t),
          const SizedBox(height: 28),

          Text('Security Question',
              style: TextStyle(
                  color: t.inkDark, fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('If you forget your PIN, you can recover it by answering this.',
              style: TextStyle(color: t.inkMid, fontSize: 13, height: 1.4)),
          const SizedBox(height: 28),

          // Question picker
          Text('Choose a question',
              style: TextStyle(
                  color: t.inkDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _qIndex,
                isExpanded: true,
                dropdownColor: t.surface,
                style: TextStyle(color: t.inkDark, fontSize: 13),
                items: List.generate(
                  AuthService.securityQuestions.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      AuthService.securityQuestions[i],
                      style: TextStyle(color: t.inkDark, fontSize: 13),
                    ),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) setState(() => _qIndex = v);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Answer input
          Text('Your answer',
              style: TextStyle(
                  color: t.inkDark, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _answerCtrl,
            style: TextStyle(color: t.inkDark, fontSize: 14),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your answer',
              hintStyle: TextStyle(color: t.inkLight),
              filled: true,
              fillColor: t.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.primary, width: 1.8)),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Note: The answer is case-insensitive and stored securely.',
            style: TextStyle(color: t.inkLight, fontSize: 11, height: 1.4),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _saveAll,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      widget.mode == 'change' ? 'Update PIN' : 'Set PIN',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared PIN widgets ────────────────────────────────────────────────────────

class StepDots extends StatelessWidget {
  final int current; // 0-based
  final int total;
  final AppTheme theme;

  const StepDots(
      {super.key, required this.current, required this.total, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done || active ? theme.primary : theme.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class PinDots extends StatelessWidget {
  final int entered;
  final AppTheme theme;

  const PinDots({super.key, required this.entered, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < entered;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? theme.primary : Colors.transparent,
            border: Border.all(
              color: filled ? theme.primary : theme.inkLight,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}

class Numpad extends StatelessWidget {
  final void Function(String) onKey;
  final VoidCallback onDelete;
  final AppTheme theme;

  const Numpad(
      {super.key, required this.onKey, required this.onDelete, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 12),
          _row(['4', '5', '6']),
          const SizedBox(height: 12),
          _row(['7', '8', '9']),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72), // empty left cell
              NumKey(label: '0', onTap: () => onKey('0'), theme: theme),
              SizedBox(
                width: 72,
                height: 72,
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: const CircleBorder(),
                    foregroundColor: theme.inkDark,
                  ),
                  onPressed: onDelete,
                  child: Icon(Icons.backspace_outlined,
                      color: theme.inkDark, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits
            .map((d) => NumKey(label: d, onTap: () => onKey(d), theme: theme))
            .toList(),
      );
}

class NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppTheme theme;

  const NumKey(
      {super.key, required this.label, required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: theme.surface,
          foregroundColor: theme.inkDark,
          shape: const CircleBorder(),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: theme.inkDark,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
