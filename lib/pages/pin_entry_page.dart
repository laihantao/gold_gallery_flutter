import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'pin_setup_page.dart' show PinDots, Numpad, PinSetupPage;

/// Full-screen PIN entry gate shown after the splash screen.
/// Navigates to [destinationRoute] on success (defaults to '/').
class PinEntryPage extends StatefulWidget {
  final String destinationRoute;
  const PinEntryPage({super.key, this.destinationRoute = '/'});

  @override
  State<PinEntryPage> createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  int _attempts = 0;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _loadAttempts();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAttempts() async {
    final count = await AuthService.getAttempts();
    if (mounted) setState(() => _attempts = count);
  }

  AppTheme get _t => context.read<ThemeNotifier>().currentTheme;

  bool get _isLocked => _attempts >= AuthService.maxAttempts;

  void _onKey(String d) {
    if (_isLocked || _pin.length >= 4) return;
    setState(() => _pin += d);
    if (_pin.length == 4) _verify();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    final ok = await AuthService.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      await AuthService.resetAttempts();
      if (mounted) context.go(widget.destinationRoute);
    } else {
      final count = await AuthService.incrementAttempts();
      if (!mounted) return;
      setState(() {
        _attempts = count;
        _pin = '';
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  // ── Forgot PIN ────────────────────────────────────────────────────────────

  Future<void> _showForgotSheet() async {
    final question = await AuthService.getSecurityQuestion();
    if (!mounted) return;

    if (question == null) {
      _showDisableDialog();
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ForgotPinSheet(
        question: question,
        theme: _t,
        onVerified: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PinSetupPage(
                mode: 'change',
                onComplete: () {
                  Navigator.of(context).pop();
                  context.go(widget.destinationRoute);
                },
              ),
            ),
          );
        },
        onDisable: () {
          Navigator.of(context).pop();
          _showDisableDialog();
        },
      ),
    );
  }

  Future<void> _showDisableDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Disable App Lock',
            style: TextStyle(
                color: _t.inkDark,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Your jewelry data will remain intact, but the PIN lock will be removed.',
          style: TextStyle(color: _t.inkMid, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: _t.inkLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _t.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AuthService.disablePin();
      if (mounted) context.go(widget.destinationRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeNotifier>().currentTheme;
    final remaining = AuthService.maxAttempts - _attempts;

    return Scaffold(
      backgroundColor: t.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Lock icon + app name
            Icon(Icons.lock_rounded, size: 48, color: t.primary),
            const SizedBox(height: 16),
            Text(
              'Pocket Gold',
              style: TextStyle(
                color: t.inkDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your 4-digit PIN',
              style: TextStyle(color: t.inkMid, fontSize: 13),
            ),

            const SizedBox(height: 40),

            // PIN dots with shake
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0),
                child: child,
              ),
              child: PinDots(entered: _pin.length, theme: t),
            ),

            const SizedBox(height: 20),

            // Attempt / lockout message
            if (_isLocked)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    Text(
                      'Too many wrong attempts.',
                      style: TextStyle(
                          color: t.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Forgot PIN?" to recover or disable app lock.',
                      style: TextStyle(color: t.inkMid, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else if (_attempts > 0)
              Text(
                '$remaining attempt${remaining == 1 ? '' : 's'} remaining',
                style: TextStyle(color: t.warning, fontSize: 12),
              ),

            const Spacer(),

            // Numpad (disabled when locked)
            IgnorePointer(
              ignoring: _isLocked,
              child: Opacity(
                opacity: _isLocked ? 0.35 : 1.0,
                child: Numpad(onKey: _onKey, onDelete: _onDelete, theme: t),
              ),
            ),

            const SizedBox(height: 24),

            // Forgot PIN button (always visible, more prominent when locked)
            TextButton(
              onPressed: _showForgotSheet,
              child: Text(
                'Forgot PIN?',
                style: TextStyle(
                  color: _isLocked ? t.primary : t.inkMid,
                  fontSize: _isLocked ? 15 : 13,
                  fontWeight:
                      _isLocked ? FontWeight.w700 : FontWeight.w500,
                  decoration: TextDecoration.underline,
                  decorationColor: _isLocked ? t.primary : t.inkMid,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Forgot PIN bottom sheet ───────────────────────────────────────────────────

class _ForgotPinSheet extends StatefulWidget {
  final String question;
  final AppTheme theme;
  final VoidCallback onVerified;
  final VoidCallback onDisable;

  const _ForgotPinSheet({
    required this.question,
    required this.theme,
    required this.onVerified,
    required this.onDisable,
  });

  @override
  State<_ForgotPinSheet> createState() => _ForgotPinSheetState();
}

class _ForgotPinSheetState extends State<_ForgotPinSheet> {
  final TextEditingController _ctrl = TextEditingController();
  int _wrongCount = 0;
  bool _checking = false;

  AppTheme get _t => widget.theme;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _checking = true);
    final ok = await AuthService.verifySecurityAnswer(_ctrl.text);
    if (!mounted) return;
    setState(() => _checking = false);

    if (ok) {
      await AuthService.resetAttempts();
      widget.onVerified();
    } else {
      setState(() {
        _wrongCount++;
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: _t.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _t.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _t.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(Icons.security_rounded, color: _t.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security Question',
                style: TextStyle(
                    color: _t.inkDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            widget.question,
            style: TextStyle(
                color: _t.inkDark, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _ctrl,
            autofocus: true,
            style: TextStyle(color: _t.inkDark, fontSize: 14),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your answer',
              hintStyle: TextStyle(color: _t.inkLight),
              errorText: _wrongCount > 0 ? 'Wrong answer, try again.' : null,
              filled: true,
              fillColor: _t.primaryBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _t.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _t.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _t.primary, width: 1.8)),
            ),
            onSubmitted: (_) => _verify(),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _t.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _checking ? null : _verify,
              child: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Verify',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),

          if (_wrongCount >= 2) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: widget.onDisable,
                child: Text(
                  'Disable App Lock instead',
                  style: TextStyle(
                    color: _t.error,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: _t.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
