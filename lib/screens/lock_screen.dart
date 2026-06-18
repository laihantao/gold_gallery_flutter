import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme/theme_notifier.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  bool _isAuthenticating = false;
  bool _failed = false;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 12).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _authenticate();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() {
      _isAuthenticating = true;
      _failed = false;
    });
    final ok = await AuthService.authenticate();
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isAuthenticating = false;
        _failed = true;
      });
      _shakeCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;

    return Scaffold(
      backgroundColor: appTheme.primaryBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo / icon
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                        _failed ? _shakeAnim.value * (_shakeCtrl.value < 0.5 ? 1 : -1) : 0,
                        0),
                    child: child,
                  ),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _failed
                          ? appTheme.error.withValues(alpha: 0.12)
                          : appTheme.primaryLight,
                      border: Border.all(
                        color: _failed ? appTheme.error : appTheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _failed
                          ? Icons.lock_outline_rounded
                          : Icons.fingerprint_rounded,
                      color: _failed ? appTheme.error : appTheme.primary,
                      size: 42,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Gold Gallery',
                  style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? 'Authentication failed. Try again.'
                      : 'Verify your identity to continue',
                  style: TextStyle(
                    color: _failed ? appTheme.error : appTheme.inkMid,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _failed
                          ? appTheme.error
                          : appTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: Icon(
                      _isAuthenticating
                          ? Icons.hourglass_top_rounded
                          : Icons.fingerprint_rounded,
                      size: 20,
                    ),
                    label: Text(
                      _isAuthenticating
                          ? 'Authenticating…'
                          : _failed
                              ? 'Try Again'
                              : 'Unlock',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
