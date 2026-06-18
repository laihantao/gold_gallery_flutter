import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/gold_alert.dart';
import '../providers/gold_price_notifier.dart';
import '../services/gold_alert_service.dart';
import '../services/gold_price_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'gold_price_card.dart';

class GoldPriceSection extends StatefulWidget {
  const GoldPriceSection({super.key});

  @override
  State<GoldPriceSection> createState() => _GoldPriceSectionState();
}

class _GoldPriceSectionState extends State<GoldPriceSection> {
  bool _didCheck = false;

  void _maybeCheckAlerts(
      GoldPriceNotifier notifier, GoldAlertNotifier alertNotifier) {
    if (notifier.isAnyLoading) {
      _didCheck = false;
      return;
    }
    if (_didCheck) return;
    _didCheck = true;

    final prices = <String, Map<String, double?>>{};
    for (final entry in notifier.allStates.entries) {
      if (entry.value.status == GoldPriceStatus.success) {
        prices[entry.key] = {
          '916': entry.value.data?.price916,
          '999': entry.value.data?.price999,
        };
      }
    }
    if (prices.isNotEmpty) {
      alertNotifier.checkPrices(prices);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeNotifier>().currentTheme;
    final l10n = context.l10n;
    final sources = GoldPriceService.sources;
    final alertNotifier = context.watch<GoldAlertNotifier>();

    return Consumer<GoldPriceNotifier>(
      builder: (context, notifier, _) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _maybeCheckAlerts(notifier, alertNotifier),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Triggered alert banners ──
            if (alertNotifier.triggered.isNotEmpty) ...[
              ...alertNotifier.triggered.map(
                (t) => _AlertBanner(
                  triggered: t,
                  appTheme: appTheme,
                  onDismiss: () => alertNotifier.dismiss(t),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // ── Section header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.homePriceTrendHint,
                    style: TextStyle(
                      color: appTheme.textBody.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: l10n.refreshTooltip,
                  onPressed:
                      notifier.isAnyLoading ? null : notifier.fetchAll,
                  icon: notifier.isAnyLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: appTheme.accentPrimary,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: appTheme.accentSecondary,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Price cards with bell icon ──
            Column(
              children: [
                for (var i = 0; i < sources.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _AlertableCard(
                    source: sources[i],
                    state: notifier.stateFor(sources[i].shopName),
                    alertNotifier: alertNotifier,
                    appTheme: appTheme,
                    onRetry: () => notifier.retry(sources[i].shopName),
                    onTap: () => context.push(
                      '/gold-history',
                      extra: sources[i].shopName,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

// ── Card with bell icon overlay ───────────────────────────────────────────────

class _AlertableCard extends StatelessWidget {
  final GoldPriceSource source;
  final ShopPriceState state;
  final GoldAlertNotifier alertNotifier;
  final AppTheme appTheme;
  final VoidCallback? onRetry;
  final VoidCallback? onTap;

  const _AlertableCard({
    required this.source,
    required this.state,
    required this.alertNotifier,
    required this.appTheme,
    this.onRetry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shopAlerts = alertNotifier.alertsFor(source.shopName);
    final hasActive = shopAlerts.any((a) => a.isActive);

    return Stack(
      children: [
        GoldPriceCard(
          shopName: source.shopName,
          logoAsset: source.logoAsset,
          state: state,
          appTheme: appTheme,
          onRetry: onRetry,
          onTap: onTap,
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _showAlertSheet(context, source.shopName, state),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: hasActive
                    ? appTheme.primary.withValues(alpha: 0.15)
                    : appTheme.surface.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasActive
                      ? appTheme.primary
                      : appTheme.border,
                  width: 1,
                ),
              ),
              child: Icon(
                hasActive
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                size: 14,
                color: hasActive ? appTheme.primary : appTheme.inkLight,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAlertSheet(
      BuildContext context, String shopName, ShopPriceState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AlertSheet(
        shopName: shopName,
        currentPrice916: state.data?.price916,
        currentPrice999: state.data?.price999,
        alertNotifier: context.read<GoldAlertNotifier>(),
        appTheme: appTheme,
      ),
    );
  }
}

// ── Alert bottom sheet ────────────────────────────────────────────────────────

class _AlertSheet extends StatefulWidget {
  final String shopName;
  final double? currentPrice916;
  final double? currentPrice999;
  final GoldAlertNotifier alertNotifier;
  final AppTheme appTheme;

  const _AlertSheet({
    required this.shopName,
    required this.currentPrice916,
    required this.currentPrice999,
    required this.alertNotifier,
    required this.appTheme,
  });

  @override
  State<_AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<_AlertSheet> {
  late final TextEditingController _ctrl916;
  late final TextEditingController _ctrl999;
  bool _above916 = true;
  bool _above999 = true;
  bool _active916 = false;
  bool _active999 = false;

  AppTheme get appTheme => widget.appTheme;

  @override
  void initState() {
    super.initState();
    final existing = widget.alertNotifier.alertsFor(widget.shopName);

    final a916 = existing.firstWhere(
      (a) => a.purity == '916',
      orElse: () => GoldAlert(
        shopName: widget.shopName,
        purity: '916',
        targetPrice: widget.currentPrice916 ?? 300,
        alertAbove: true,
        isActive: false,
      ),
    );
    final a999 = existing.firstWhere(
      (a) => a.purity == '999',
      orElse: () => GoldAlert(
        shopName: widget.shopName,
        purity: '999',
        targetPrice: widget.currentPrice999 ?? 320,
        alertAbove: true,
        isActive: false,
      ),
    );

    _ctrl916 = TextEditingController(
        text: a916.targetPrice.toStringAsFixed(2));
    _ctrl999 = TextEditingController(
        text: a999.targetPrice.toStringAsFixed(2));
    _above916 = a916.alertAbove;
    _above999 = a999.alertAbove;
    _active916 = a916.isActive;
    _active999 = a999.isActive;
  }

  @override
  void dispose() {
    _ctrl916.dispose();
    _ctrl999.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    Future<void> saveAlert(
        String purity, TextEditingController ctrl, bool above, bool active) async {
      final price = double.tryParse(ctrl.text.trim());
      if (price == null || price <= 0) return;
      final alert = GoldAlert(
        shopName: widget.shopName,
        purity: purity,
        targetPrice: price,
        alertAbove: above,
        isActive: active,
      );
      if (active) {
        await widget.alertNotifier.addOrUpdate(alert);
      } else {
        await widget.alertNotifier.remove(alert);
      }
    }

    await saveAlert('916', _ctrl916, _above916, _active916);
    await saveAlert('999', _ctrl999, _above999, _active999);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: appTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: appTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined,
                      color: appTheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Price Alerts — ${widget.shopName}',
                    style: TextStyle(
                      color: appTheme.inkDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: appTheme.border),

            _AlertRow(
              purity: '916',
              currentPrice: widget.currentPrice916,
              ctrl: _ctrl916,
              above: _above916,
              active: _active916,
              appTheme: appTheme,
              onAboveChanged: (v) => setState(() => _above916 = v),
              onActiveChanged: (v) => setState(() => _active916 = v),
            ),
            Divider(
                color: appTheme.border.withValues(alpha: 0.4), indent: 16),
            _AlertRow(
              purity: '999',
              currentPrice: widget.currentPrice999,
              ctrl: _ctrl999,
              above: _above999,
              active: _active999,
              appTheme: appTheme,
              onAboveChanged: (v) => setState(() => _above999 = v),
              onActiveChanged: (v) => setState(() => _active999 = v),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: _save,
                  child: const Text('Save Alerts',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final String purity;
  final double? currentPrice;
  final TextEditingController ctrl;
  final bool above;
  final bool active;
  final AppTheme appTheme;
  final ValueChanged<bool> onAboveChanged;
  final ValueChanged<bool> onActiveChanged;

  const _AlertRow({
    required this.purity,
    required this.currentPrice,
    required this.ctrl,
    required this.above,
    required this.active,
    required this.appTheme,
    required this.onAboveChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Purity label
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: appTheme.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              purity,
              style: TextStyle(
                  color: appTheme.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),

          // Above / Below toggle
          GestureDetector(
            onTap: () => onAboveChanged(!above),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: above
                    ? const Color(0xFF3DAA3D).withValues(alpha: 0.12)
                    : const Color(0xFFCC4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: above
                      ? const Color(0xFF3DAA3D)
                      : const Color(0xFFCC4444),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    above
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color:
                        above ? const Color(0xFF3DAA3D) : const Color(0xFFCC4444),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    above ? '≥' : '≤',
                    style: TextStyle(
                      color: above
                          ? const Color(0xFF3DAA3D)
                          : const Color(0xFFCC4444),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Price input
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: appTheme.inkDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                prefixText: 'RM ',
                prefixStyle: TextStyle(
                    color: appTheme.inkLight, fontSize: 12),
                filled: true,
                fillColor: appTheme.primaryBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: appTheme.border, width: 0.8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: appTheme.primary, width: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Active toggle
          Switch(
            value: active,
            onChanged: onActiveChanged,
            activeThumbColor: appTheme.primary,
            activeTrackColor: appTheme.primaryLight,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Triggered alert banner ────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final TriggeredAlert triggered;
  final AppTheme appTheme;
  final VoidCallback onDismiss;

  const _AlertBanner({
    required this.triggered,
    required this.appTheme,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final alert = triggered.alert;
    final isAbove = alert.alertAbove;
    final color = isAbove ? const Color(0xFF3DAA3D) : const Color(0xFFCC4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    color: appTheme.inkDark,
                    fontSize: 11,
                    height: 1.4),
                children: [
                  TextSpan(
                    text: '${alert.shopName} ${alert.purity} ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                      text:
                          '${isAbove ? 'reached' : 'dropped to'} RM ${triggered.currentPrice.toStringAsFixed(2)}'),
                  TextSpan(
                    text:
                        '  (target: ${isAbove ? '≥' : '≤'} RM ${alert.targetPrice.toStringAsFixed(2)})',
                    style: TextStyle(color: appTheme.inkLight),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                size: 14, color: appTheme.inkLight),
            onPressed: onDismiss,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
