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

    return GoldPriceCard(
      shopName: source.shopName,
      logoAsset: source.logoAsset,
      state: state,
      appTheme: appTheme,
      onRetry: onRetry,
      onTap: onTap,
      onAlertTap: () => _showAlertSheet(context, source.shopName, state),
      hasActiveAlert: hasActive,
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
//
// One alert at a time: choose purity → condition → enter price → Create Alert.
// Pre-fills from any existing alert for the selected purity so edits are easy.

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
  String _purity = '999';
  bool _above = true;
  late final TextEditingController _priceCtrl;
  bool _isSaving = false;

  AppTheme get _t => widget.appTheme;

  GoldAlert? _existingFor(String purity) {
    for (final a in widget.alertNotifier.alertsFor(widget.shopName)) {
      if (a.purity == purity) return a;
    }
    return null;
  }

  double? get _currentPriceForPurity =>
      _purity == '999' ? widget.currentPrice999 : widget.currentPrice916;

  @override
  void initState() {
    super.initState();
    final existing = _existingFor('999') ?? _existingFor('916');
    if (existing != null) {
      _purity = existing.purity;
      _above = existing.alertAbove;
      _priceCtrl = TextEditingController(
          text: existing.targetPrice.toStringAsFixed(0));
    } else {
      _priceCtrl = TextEditingController(
          text: widget.currentPrice999?.toStringAsFixed(0) ?? '');
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    super.dispose();
  }

  void _switchPurity(String purity) {
    if (purity == _purity) return;
    final existing = _existingFor(purity);
    setState(() {
      _purity = purity;
      if (existing != null) {
        _above = existing.alertAbove;
        _priceCtrl.text = existing.targetPrice.toStringAsFixed(0);
      } else if (_priceCtrl.text.trim().isEmpty) {
        final p = _currentPriceForPurity;
        if (p != null) _priceCtrl.text = p.toStringAsFixed(0);
      }
    });
  }

  Future<void> _create() async {
    final raw = _priceCtrl.text.trim().replaceAll(',', '.');
    final price = double.tryParse(raw);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _t.error,
        content: const Text('Please enter a valid price.'),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.alertNotifier.addOrUpdate(GoldAlert(
        shopName: widget.shopName,
        purity: _purity,
        targetPrice: price,
        alertAbove: _above,
        isActive: true,
      ));
      if (!mounted) return;
      // Capture messenger before popping so we can show the snackbar after.
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        backgroundColor: _t.snackBarBg,
        content: Text(
          'Price alert created! '
          '${widget.shopName} $_purity ${_above ? '≥' : '≤'} '
          'RM ${price.toStringAsFixed(0)}',
        ),
        duration: const Duration(seconds: 3),
      ));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _t.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _t.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 2),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _t.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
              child: Row(
                children: [
                  Icon(Icons.notifications_outlined,
                      color: _t.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Price Alert — ${widget.shopName}',
                    style: TextStyle(
                      color: _t.inkDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _t.border),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Purity ──────────────────────────────────────
                  _SheetLabel(label: 'Purity', appTheme: _t),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ChoiceChip(
                        label: '999',
                        selected: _purity == '999',
                        activeColor: _t.primary,
                        appTheme: _t,
                        onTap: () => _switchPurity('999'),
                      ),
                      const SizedBox(width: 10),
                      _ChoiceChip(
                        label: '916',
                        selected: _purity == '916',
                        activeColor: _t.primary,
                        appTheme: _t,
                        onTap: () => _switchPurity('916'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Condition ───────────────────────────────────
                  _SheetLabel(label: 'When price is', appTheme: _t),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ChoiceChip(
                        label: '≥  Above or equal',
                        selected: _above,
                        activeColor: const Color(0xFF3DAA3D),
                        appTheme: _t,
                        onTap: () => setState(() => _above = true),
                      ),
                      const SizedBox(width: 10),
                      _ChoiceChip(
                        label: '≤  Below or equal',
                        selected: !_above,
                        activeColor: const Color(0xFFCC4444),
                        appTheme: _t,
                        onTap: () => setState(() => _above = false),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Target price ────────────────────────────────
                  _SheetLabel(label: 'Target Price', appTheme: _t),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: _t.inkDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'RM  ',
                      prefixStyle: TextStyle(
                        color: _t.inkMid,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: _t.primaryBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _t.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: _t.border, width: 0.8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: _t.primary, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Create button ───────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _t.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(
                              Icons.notifications_active_rounded,
                              size: 18),
                      label: Text(
                        _isSaving ? 'Creating…' : 'Create Alert',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _isSaving ? null : _create,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sheet label ──────────────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String label;
  final AppTheme appTheme;
  const _SheetLabel({required this.label, required this.appTheme});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
          color: appTheme.inkMid,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      );
}

// ── Segmented choice chip ─────────────────────────────────────────────────────

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final AppTheme appTheme;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.appTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.12)
              : appTheme.primaryBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? activeColor : appTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : appTheme.inkMid,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
