import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../components/app_header.dart';
import '../l10n/app_localizations.dart';
import '../models/gold_alert.dart';
import '../services/gold_alert_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

/// Centralised page listing every active price alert.
///
/// Each card shows brand, purity, condition, and target price.
/// Swipe left to reveal the delete action, or tap the delete icon.
/// No toggles — everything shown here is an active alert. To remove
/// an alert, delete it; to add one, tap the bell icon on the home page.
class PriceAlertsPage extends StatelessWidget {
  const PriceAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppHeader(
        title: l10n.priceAlertsSection,
        showBackButton: true,
        actions: [
          _TestNotificationButton(appTheme: appTheme, l10n: l10n),
        ],
      ),
      body: Consumer<GoldAlertNotifier>(
        builder: (context, alertNotifier, _) {
          final alerts = alertNotifier.alerts;

          if (alerts.isEmpty) {
            return _EmptyState(appTheme: appTheme, l10n: l10n);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _DismissibleAlertCard(
              key: ValueKey(alerts[i].id),
              alert: alerts[i],
              alertNotifier: alertNotifier,
              appTheme: appTheme,
              l10n: l10n,
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final AppTheme appTheme;
  final AppLocalizations l10n;

  const _EmptyState({required this.appTheme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 52, color: appTheme.inkLight),
            const SizedBox(height: 14),
            Text(
              l10n.noAlertsConfigured,
              style: TextStyle(
                color: appTheme.inkMid,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noAlertsHint,
              style: TextStyle(color: appTheme.inkLight, fontSize: 12, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dismissible alert card ────────────────────────────────────────────────────

class _DismissibleAlertCard extends StatelessWidget {
  final GoldAlert alert;
  final GoldAlertNotifier alertNotifier;
  final AppTheme appTheme;
  final AppLocalizations l10n;

  const _DismissibleAlertCard({
    super.key,
    required this.alert,
    required this.alertNotifier,
    required this.appTheme,
    required this.l10n,
  });

  void _showDeletedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: appTheme.snackBarBg,
        content: Text(
          l10n.alertDeleted(alert.shopName, alert.purity),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(alert.id),
      direction: DismissDirection.endToStart,
      // Red delete background revealed on swipe left
      background: Container(
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: appTheme.error,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            const SizedBox(height: 4),
            Text(
              l10n.deleteButton,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) {
        alertNotifier.remove(alert);
        _showDeletedSnackBar(context);
      },
      child: _AlertCard(
        alert: alert,
        alertNotifier: alertNotifier,
        appTheme: appTheme,
        l10n: l10n,
        onDelete: () {
          alertNotifier.remove(alert);
          _showDeletedSnackBar(context);
        },
      ),
    );
  }
}

// ── Alert card content ────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final GoldAlert alert;
  final GoldAlertNotifier alertNotifier;
  final AppTheme appTheme;
  final AppLocalizations l10n;
  final VoidCallback onDelete;

  const _AlertCard({
    required this.alert,
    required this.alertNotifier,
    required this.appTheme,
    required this.l10n,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dirColor =
        alert.alertAbove ? appTheme.success : appTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: appTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: appTheme.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // Brand + purity column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.shopName,
                  style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Purity badge
                    _Badge(
                      label: alert.purity,
                      bgColor: appTheme.primaryLight,
                      textColor: appTheme.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    // Direction badge
                    _Badge(
                      label:
                          '${alert.alertAbove ? '≥' : '≤'}  ${alert.alertAbove ? 'Above' : 'Below'}',
                      bgColor: dirColor.withValues(alpha: 0.1),
                      textColor: dirColor,
                      borderColor: dirColor.withValues(alpha: 0.5),
                      icon: alert.alertAbove
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      iconColor: dirColor,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Target price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${alert.targetPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: appTheme.inkDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'target',
                style: TextStyle(
                    color: appTheme.inkLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Delete icon
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: appTheme.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: appTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge widget ──────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final Color? borderColor;
  final IconData? icon;
  final Color? iconColor;

  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.borderColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 0.8)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: iconColor),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Test notification button (AppBar action) ──────────────────────────────────

class _TestNotificationButton extends StatefulWidget {
  final AppTheme appTheme;
  final AppLocalizations l10n;

  const _TestNotificationButton({required this.appTheme, required this.l10n});

  @override
  State<_TestNotificationButton> createState() =>
      _TestNotificationButtonState();
}

class _TestNotificationButtonState extends State<_TestNotificationButton> {
  bool _isTesting = false;

  static const List<String> _brands = ['Chiang Heng', 'Poh Kong', 'Tomei'];
  static const List<String> _purities = ['916', '999'];

  String _selectedBrand = 'Poh Kong';
  String _selectedPurity = '916';

  AppTheme get _t => widget.appTheme;

  Future<void> _showTestDialog() async {
    String brand = _selectedBrand;
    String purity = _selectedPurity;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: _t.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  color: _t.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.l10n.testNotifTitle,
                style: TextStyle(
                    color: _t.inkDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.l10n.testNotifDesc,
                style: TextStyle(color: _t.inkMid, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(widget.l10n.filterBrand,
                  style: TextStyle(
                      color: _t.inkDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _t.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _t.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: brand,
                    isExpanded: true,
                    dropdownColor: _t.surface,
                    style: TextStyle(
                        color: _t.inkDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    items: _brands
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setInner(() => brand = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(widget.l10n.filterPurity,
                  style: TextStyle(
                      color: _t.inkDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: _purities.map((p) {
                  final active = purity == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setInner(() => purity = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.only(right: p == '916' ? 6 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? _t.primary.withValues(alpha: 0.12)
                              : _t.primaryBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: active ? _t.primary : _t.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          p,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? _t.primary : _t.inkMid,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(widget.l10n.cancelButton,
                  style: TextStyle(color: _t.inkLight)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _t.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(widget.l10n.sendTestNotif),
              onPressed: () {
                _selectedBrand = brand;
                _selectedPurity = purity;
                Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    await _sendTest();
  }

  Future<void> _sendTest() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);
    try {
      final granted = await NotificationService.requestPermission();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _t.error,
            content: Text(widget.l10n.notifPermDenied),
          ),
        );
        return;
      }
      await NotificationService.showTestAlert(
        shopName: _selectedBrand,
        purity: _selectedPurity,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _t.snackBarBg,
          content: Text(widget.l10n.testNotifSent),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isTesting
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: _t.primary),
            ),
          )
        : IconButton(
            icon: Icon(Icons.notifications_active_outlined,
                color: _t.inkDark, size: 22),
            tooltip: widget.l10n.testNotifButton,
            onPressed: _showTestDialog,
          );
  }
}
